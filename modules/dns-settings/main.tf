# -----------------------------------------------------------------------------
# Submodule: dns-settings
#
#   cloudflare_account_dns_settings  the one set of account wide DNS defaults
#   cloudflare_dns_firewall          a DNS Firewall resolver cluster
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  create_dns_settings = local.enabled && var.create_dns_settings
  dns_firewalls       = local.enabled ? var.dns_firewalls : {}
}

resource "cloudflare_account_dns_settings" "this" {
  count = local.create_dns_settings ? 1 : 0

  account_id       = var.account_id
  enforce_dns_only = var.enforce_dns_only
  zone_defaults    = var.zone_defaults
}

resource "cloudflare_dns_firewall" "this" {
  for_each = local.dns_firewalls

  account_id             = var.account_id
  name                   = each.value.name
  upstream_ips           = each.value.upstream_ips
  deprecate_any_requests = each.value.deprecate_any_requests
  dns_firewall_ip_count  = each.value.dns_firewall_ip_count
  ecs_fallback           = each.value.ecs_fallback
  maximum_cache_ttl      = each.value.maximum_cache_ttl
  minimum_cache_ttl      = each.value.minimum_cache_ttl
  negative_cache_ttl     = each.value.negative_cache_ttl
  ratelimit              = each.value.ratelimit
  retries                = each.value.retries
  attack_mitigation      = each.value.attack_mitigation
}
