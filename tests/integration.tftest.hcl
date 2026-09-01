# Applies against a real Cloudflare test account.
# Runs on a schedule and on manual dispatch only, never on pull requests,
# because fork pull requests cannot read organisation secrets.
#
# The account itself is never created here. Account creation needs a tenant or
# reseller relationship and the object cannot be cleanly destroyed afterwards.

variables {
  account_id = null # supplied by TF_VAR_account_id
}

run "apply_and_destroy" {
  command = apply

  variables {
    groups = {
      integration_test = {
        name = "terraform-integration-test"
      }
    }

    notification_webhooks = {
      integration_test = {
        name = "terraform-integration-test"
        url  = "https://example.com/terraform-integration-test"
      }
    }

    notification_policies = {
      integration_test = {
        name         = "terraform-integration-test"
        alert_type   = "http_alert_origin_error"
        enabled      = false
        webhook_keys = ["integration_test"]
      }
    }
  }

  assert {
    condition     = output.enabled == true
    error_message = "Module did not report enabled after apply."
  }

  assert {
    condition     = length(output.group_ids) == 1
    error_message = "Module did not create the test user group."
  }

  assert {
    condition     = length(output.notification_policy_ids) == 1
    error_message = "Module did not create the test notification policy."
  }
}
