# Minimum viable configuration for the Cloudflare Account module.
#
# Points at an existing account, invites one member, and sends the standard
# "your origin is erroring" alert to an email address.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id

  members = {
    platform_lead = {
      email = "platform@example.com"
      roles = [var.administrator_role_id]
    }
  }

  notification_policies = {
    origin_errors = {
      name       = "Origin error rate"
      alert_type = "http_alert_origin_error"
      emails     = ["platform@example.com"]
    }
  }
}
