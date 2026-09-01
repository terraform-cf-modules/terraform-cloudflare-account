# Plan only. Runs on every pull request, including forks, with no credentials.

mock_provider "cloudflare" {
  override_during = plan
}

variables {
  account_id = "00000000000000000000000000000000"
}

run "creates_nothing_when_disabled" {
  command = plan

  variables {
    enabled = false

    members = {
      platform_lead = {
        email = "platform@example.com"
      }
    }

    groups = {
      network_engineers = { name = "Network engineers" }
    }

    notification_policies = {
      origin_errors = {
        name       = "Origin error rate"
        alert_type = "http_alert_origin_error"
        emails     = ["platform@example.com"]
      }
    }
  }

  assert {
    condition     = output.enabled == false
    error_message = "Module reported enabled while var.enabled was false."
  }

  assert {
    condition     = length(output.member_ids) == 0
    error_message = "Module created account members while disabled."
  }

  assert {
    condition     = length(output.group_ids) == 0
    error_message = "Module created user groups while disabled."
  }

  assert {
    condition     = length(output.notification_policy_ids) == 0
    error_message = "Module created notification policies while disabled."
  }
}

run "enabled_by_default" {
  command = plan

  assert {
    condition     = output.enabled == true
    error_message = "Module should be enabled by default."
  }

  assert {
    condition     = output.account == null
    error_message = "Module created an account while create_account was false."
  }

  assert {
    condition     = output.account_id == "00000000000000000000000000000000"
    error_message = "Module did not anchor on the supplied account_id."
  }
}

run "creates_the_account_when_asked" {
  command = plan

  variables {
    account_id     = null
    create_account = true
    account_name   = "platform"

    account_settings = {
      abuse_contact_email = "abuse@example.com"
      enforce_twofactor   = true
    }
  }

  assert {
    condition     = output.account != null
    error_message = "Module did not create an account while create_account was true."
  }

  assert {
    condition     = cloudflare_account.this[0].name == "platform"
    error_message = "Account name did not come from var.account_name."
  }

  assert {
    condition     = cloudflare_account.this[0].settings.enforce_twofactor == true
    error_message = "Account settings did not come from var.account_settings."
  }
}

run "creates_members_groups_and_policies" {
  command = plan

  variables {
    members = {
      platform_lead = {
        email  = "platform@example.com"
        roles  = ["00000000000000000000000000000000"]
        status = "pending"
      }

      auditor = {
        email = "audit@example.com"
        policies = [{
          access               = "allow"
          permission_group_ids = ["00000000000000000000000000000000"]
          resource_group_ids   = ["00000000000000000000000000000000"]
        }]
      }
    }

    groups = {
      network_engineers = {
        name = "Network engineers"
        policies = [{
          access               = "deny"
          permission_group_ids = ["00000000000000000000000000000000"]
          resource_group_ids   = ["00000000000000000000000000000000"]
        }]
      }
    }

    group_members = {
      network_engineers = {
        group_key   = "network_engineers"
        member_keys = ["platform_lead"]
      }
    }

    notification_webhooks = {
      ops_channel = {
        name   = "Ops channel"
        url    = "https://hooks.example.com/cloudflare"
        secret = "not-a-real-secret"
      }
    }

    notification_policies = {
      origin_errors = {
        name         = "Origin error rate"
        alert_type   = "http_alert_origin_error"
        emails       = ["platform@example.com"]
        webhook_keys = ["ops_channel"]

        filters = {
          zones = ["00000000000000000000000000000000"]
        }
      }
    }
  }

  assert {
    condition     = length(output.member_ids) == 2
    error_message = "Expected two account members."
  }

  assert {
    condition     = length(output.group_ids) == 1
    error_message = "Expected one user group."
  }

  assert {
    condition     = length(output.group_members) == 1
    error_message = "Expected one user group membership."
  }

  assert {
    condition     = length(output.notification_webhook_ids) == 1
    error_message = "Expected one webhook destination."
  }

  assert {
    condition     = length(output.notification_policy_ids) == 1
    error_message = "Expected one notification policy."
  }

  assert {
    condition     = module.member.members["platform_lead"].email == "platform@example.com"
    error_message = "Member email did not reach the resource."
  }

  assert {
    condition     = module.notification.policies["origin_errors"].alert_type == "http_alert_origin_error"
    error_message = "Notification alert_type did not reach the resource."
  }

  assert {
    condition     = module.notification.policies["origin_errors"].filters.zones == tolist(["00000000000000000000000000000000"])
    error_message = "Notification filters did not reach the resource."
  }
}
