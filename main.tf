# -----------------------------------------------------------------------------
# Module: Cloudflare Account
# Account bootstrap, members and groups, API tokens, notifications, Logpush, and
# secrets store.
#
# The root module covers the common case a platform team runs once per account:
# the account object itself, the people who can reach it, and the baseline alerts
# that tell them when something is wrong.
#
# Everything else is a building block under modules/, consumed with the double
# slash source syntax:
#
#   source = "terraform-cf-modules/account/cloudflare//modules/<name>"
# -----------------------------------------------------------------------------

resource "cloudflare_account" "this" {
  count = local.create_account ? 1 : 0

  # `type` is deliberately not set. The provider marks it deprecated:
  # "The 'type' field should no longer be set through the API."
  name     = var.account_name
  settings = var.account_settings

  unit = var.account_unit_id == null ? null : { id = var.account_unit_id }
}

module "member" {
  source = "./modules/member"

  enabled       = local.enabled
  account_id    = local.account_id
  members       = var.members
  groups        = var.groups
  group_members = var.group_members
}

module "notification" {
  source = "./modules/notification"

  enabled    = local.enabled
  account_id = local.account_id
  webhooks   = var.notification_webhooks
  policies   = var.notification_policies
}
