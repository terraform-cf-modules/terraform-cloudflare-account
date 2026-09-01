# -----------------------------------------------------------------------------
# Submodule: notification
#
#   cloudflare_notification_policy_webhooks  a webhook delivery destination
#   cloudflare_notification_policy           an alert rule and where it is delivered
#
# var.webhooks is marked sensitive because it carries the cf-webhook-auth secret.
# A sensitive value cannot be used as for_each, so the resource iterates over the
# unmarked keys and looks each entry up by key.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  webhook_keys = local.enabled ? nonsensitive(toset(keys(var.webhooks))) : toset([])
  policies     = local.enabled ? var.policies : {}
}

resource "cloudflare_notification_policy_webhooks" "this" {
  for_each = local.webhook_keys

  account_id = var.account_id
  name       = nonsensitive(var.webhooks[each.key].name)
  url        = nonsensitive(var.webhooks[each.key].url)
  secret     = var.webhooks[each.key].secret
}

resource "cloudflare_notification_policy" "this" {
  for_each = local.policies

  account_id     = var.account_id
  name           = each.value.name
  alert_type     = each.value.alert_type
  description    = each.value.description
  enabled        = each.value.enabled
  alert_interval = each.value.alert_interval
  filters        = each.value.filters

  mechanisms = {
    email     = length(each.value.emails) > 0 ? [for e in each.value.emails : { id = e }] : null
    pagerduty = length(each.value.pagerduty_ids) > 0 ? [for p in each.value.pagerduty_ids : { id = p }] : null

    webhooks = length(each.value.webhook_keys) + length(each.value.webhook_ids) > 0 ? [
      for id in concat(
        [for k in each.value.webhook_keys : cloudflare_notification_policy_webhooks.this[k].id],
        each.value.webhook_ids,
      ) : { id = id }
    ] : null
  }
}
