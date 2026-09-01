# Input validation. Plan only, no credentials.
# One case per validation block in variables.tf.

mock_provider "cloudflare" {
  override_during = plan
}

variables {
  account_id = "00000000000000000000000000000000"
}

run "rejects_malformed_account_id" {
  command = plan

  variables {
    account_id = "not-a-valid-account-id"
  }

  expect_failures = [var.account_id]
}

run "rejects_missing_account_id" {
  command = plan

  variables {
    account_id     = null
    create_account = false
  }

  expect_failures = [var.account_id]
}

run "rejects_create_account_without_a_name" {
  command = plan

  variables {
    create_account = true
    account_name   = null
  }

  expect_failures = [var.account_name]
}

run "rejects_malformed_member_email" {
  command = plan

  variables {
    members = {
      platform_lead = {
        email = "platform at example dot com"
      }
    }
  }

  expect_failures = [var.members]
}

run "rejects_malformed_notification_email" {
  command = plan

  variables {
    notification_policies = {
      origin_errors = {
        name       = "Origin error rate"
        alert_type = "http_alert_origin_error"
        emails     = ["platform at example dot com"]
      }
    }
  }

  expect_failures = [var.notification_policies]
}

run "rejects_malformed_abuse_contact_email" {
  command = plan

  variables {
    account_settings = {
      abuse_contact_email = "not an email"
    }
  }

  expect_failures = [var.account_settings]
}

run "rejects_unknown_member_status" {
  command = plan

  variables {
    members = {
      platform_lead = {
        email  = "platform@example.com"
        status = "invited"
      }
    }
  }

  expect_failures = [var.members]
}

run "rejects_unknown_member_policy_access" {
  command = plan

  variables {
    members = {
      auditor = {
        email = "audit@example.com"
        policies = [{
          access               = "maybe"
          permission_group_ids = ["00000000000000000000000000000000"]
          resource_group_ids   = ["00000000000000000000000000000000"]
        }]
      }
    }
  }

  expect_failures = [var.members]
}

run "rejects_unknown_group_policy_access" {
  command = plan

  variables {
    groups = {
      network_engineers = {
        name = "Network engineers"
        policies = [{
          access               = "maybe"
          permission_group_ids = ["00000000000000000000000000000000"]
          resource_group_ids   = ["00000000000000000000000000000000"]
        }]
      }
    }
  }

  expect_failures = [var.groups]
}

run "rejects_group_members_without_a_group_reference" {
  command = plan

  variables {
    group_members = {
      network_engineers = {
        member_ids = ["00000000000000000000000000000000"]
      }
    }
  }

  expect_failures = [var.group_members]
}

run "rejects_group_members_with_both_group_references" {
  command = plan

  variables {
    group_members = {
      network_engineers = {
        group_key     = "network_engineers"
        user_group_id = "00000000000000000000000000000000"
        member_ids    = ["00000000000000000000000000000000"]
      }
    }
  }

  expect_failures = [var.group_members]
}

run "rejects_plaintext_webhook_url" {
  command = plan

  variables {
    notification_webhooks = {
      ops_channel = {
        name = "Ops channel"
        url  = "http://hooks.example.com/cloudflare"
      }
    }
  }

  expect_failures = [var.notification_webhooks]
}

run "rejects_notification_policy_without_a_mechanism" {
  command = plan

  variables {
    notification_policies = {
      origin_errors = {
        name       = "Origin error rate"
        alert_type = "http_alert_origin_error"
      }
    }
  }

  expect_failures = [var.notification_policies]
}

run "rejects_unknown_alert_type" {
  command = plan

  variables {
    notification_policies = {
      origin_errors = {
        name       = "Origin error rate"
        alert_type = "everything_is_on_fire"
        emails     = ["platform@example.com"]
      }
    }
  }

  expect_failures = [var.notification_policies]
}
