# -----------------------------------------------------------------------------
# Submodule: api-token
#
#   cloudflare_api_token      user scoped token, inherits the creating user's reach
#   cloudflare_account_token  account scoped token, bound to one account
#
# Both resources return a `value` attribute that the API discloses exactly once.
# The schema marks it SENSITIVE and every output here does the same. The value is
# stored in Terraform state, so treat state as a secret.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  user_tokens    = local.enabled ? var.user_tokens : {}
  account_tokens = local.enabled ? var.account_tokens : {}

  # Policies arrive as a keyed map so a caller can add or remove one without shifting
  # the others. The provider wants an ordered list, so sort by key for a stable plan.
  user_token_policies = {
    for k, t in local.user_tokens : k => [
      for pk in sort(keys(t.policies)) : {
        effect            = t.policies[pk].effect
        permission_groups = [for id in t.policies[pk].permission_group_ids : { id = id }]
        resources         = coalesce(t.policies[pk].resources_json, jsonencode(t.policies[pk].resources))
      }
    ]
  }

  account_token_policies = {
    for k, t in local.account_tokens : k => [
      for pk in sort(keys(t.policies)) : {
        effect            = t.policies[pk].effect
        permission_groups = [for id in t.policies[pk].permission_group_ids : { id = id }]
        resources         = coalesce(t.policies[pk].resources_json, jsonencode(t.policies[pk].resources))
      }
    ]
  }
}

resource "cloudflare_api_token" "this" {
  for_each = local.user_tokens

  name       = each.value.name
  status     = each.value.status
  expires_on = each.value.expires_on
  not_before = each.value.not_before
  policies   = local.user_token_policies[each.key]

  condition = each.value.request_ip_in == null && each.value.request_ip_not_in == null ? null : {
    request_ip = {
      in     = each.value.request_ip_in
      not_in = each.value.request_ip_not_in
    }
  }
}

resource "cloudflare_account_token" "this" {
  for_each = local.account_tokens

  account_id = var.account_id
  name       = each.value.name
  status     = each.value.status
  expires_on = each.value.expires_on
  not_before = each.value.not_before
  policies   = local.account_token_policies[each.key]

  condition = each.value.request_ip_in == null && each.value.request_ip_not_in == null ? null : {
    request_ip = {
      in     = each.value.request_ip_in
      not_in = each.value.request_ip_not_in
    }
  }
}
