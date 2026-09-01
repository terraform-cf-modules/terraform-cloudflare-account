# -----------------------------------------------------------------------------
# Wrapper: create many instances of the root module from a single map.
#
#   module "accounts" {
#     source = "terraform-cf-modules/account/cloudflare//wrappers"
#
#     defaults = {
#       notification_policies = {
#         origin_errors = {
#           name       = "Origin error rate"
#           alert_type = "http_alert_origin_error"
#           emails     = ["platform@example.com"]
#         }
#       }
#     }
#
#     items = {
#       production = { account_id = var.production_account_id }
#       staging    = { account_id = var.staging_account_id }
#     }
#   }
# -----------------------------------------------------------------------------

module "wrapper" {
  source = "../"

  for_each = var.items

  enabled    = try(each.value.enabled, var.defaults.enabled, true)
  account_id = try(each.value.account_id, var.defaults.account_id, null)

  create_account   = try(each.value.create_account, var.defaults.create_account, false)
  account_name     = try(each.value.account_name, var.defaults.account_name, null)
  account_settings = try(each.value.account_settings, var.defaults.account_settings, null)
  account_unit_id  = try(each.value.account_unit_id, var.defaults.account_unit_id, null)

  members       = try(each.value.members, var.defaults.members, {})
  groups        = try(each.value.groups, var.defaults.groups, {})
  group_members = try(each.value.group_members, var.defaults.group_members, {})

  notification_webhooks = try(each.value.notification_webhooks, var.defaults.notification_webhooks, {})
  notification_policies = try(each.value.notification_policies, var.defaults.notification_policies, {})
}
