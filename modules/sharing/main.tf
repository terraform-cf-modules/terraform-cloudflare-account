# -----------------------------------------------------------------------------
# Submodule: sharing
#
#   cloudflare_share            a share owned by this account
#   cloudflare_share_recipient  an account or organisation added to a share
#   cloudflare_share_resource   an object added to a share
#
# A share is created with its initial recipients and resources inline. The two
# standalone resources exist for anything added after creation.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  shares     = local.enabled ? var.shares : {}
  recipients = local.enabled ? var.recipients : {}
  resources  = local.enabled ? var.resources : {}
}

resource "cloudflare_share" "this" {
  for_each = local.shares

  account_id = var.account_id
  name       = each.value.name

  recipients = [
    for r in each.value.recipients : {
      recipient_account_id = r.recipient_account_id
      organization_id      = r.organization_id
    }
  ]

  resources = [
    for r in each.value.resources : {
      resource_id         = r.resource_id
      resource_type       = r.resource_type
      resource_account_id = r.resource_account_id
      meta                = r.meta
    }
  ]
}

resource "cloudflare_share_recipient" "this" {
  for_each = local.recipients

  account_id           = var.account_id
  share_id             = each.value.share_id != null ? each.value.share_id : cloudflare_share.this[each.value.share_key].id
  recipient_account_id = each.value.recipient_account_id
  organization_id      = each.value.organization_id
}

resource "cloudflare_share_resource" "this" {
  for_each = local.resources

  account_id          = var.account_id
  share_id            = each.value.share_id != null ? each.value.share_id : cloudflare_share.this[each.value.share_key].id
  resource_id         = each.value.resource_id
  resource_type       = each.value.resource_type
  resource_account_id = each.value.resource_account_id
  meta                = each.value.meta
}
