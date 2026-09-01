locals {
  # Single switch consulted by every resource in this module.
  enabled = var.enabled

  create_account = local.enabled && var.create_account

  # Everything downstream anchors on this. When the account is created here it is
  # unknown until apply, which is expected.
  account_id = local.create_account ? one(cloudflare_account.this[*].id) : var.account_id
}
