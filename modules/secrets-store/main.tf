# -----------------------------------------------------------------------------
# Submodule: secrets-store
#
#   cloudflare_secrets_store         a named store scoped to one account
#   cloudflare_secrets_store_secret  one secret inside a store
#
# var.secrets is marked sensitive because it carries the secret material.
# Terraform refuses a sensitive value as for_each, so the local below builds a
# view with `value` blanked out, unmarks that, and drives for_each from it. The
# real value is read straight from the variable at the point of use.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  stores = local.enabled ? var.stores : {}

  secrets = local.enabled ? nonsensitive({
    for k, v in var.secrets : k => merge(v, { value = null })
  }) : {}
}

resource "cloudflare_secrets_store" "this" {
  for_each = local.stores

  account_id = var.account_id
  name       = each.value.name
}

resource "cloudflare_secrets_store_secret" "this" {
  for_each = local.secrets

  account_id = var.account_id
  store_id   = each.value.store_id != null ? each.value.store_id : cloudflare_secrets_store.this[each.value.store_key].id
  name       = each.value.name
  scopes     = each.value.scopes
  comment    = each.value.comment
  value      = var.secrets[each.key].value
}
