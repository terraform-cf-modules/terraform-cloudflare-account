output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "dns_settings" {
  description = "The cloudflare_account_dns_settings resource, or null when not managed."
  value       = one(cloudflare_account_dns_settings.this)
}

output "dns_settings_account_id" {
  description = "Account ID of the managed DNS settings, or null when not managed."
  value       = try(one(cloudflare_account_dns_settings.this).account_id, null)
}

output "dns_firewalls" {
  description = "Map of created cloudflare_dns_firewall resources, keyed as in var.dns_firewalls."
  value       = cloudflare_dns_firewall.this
}

output "dns_firewall_ids" {
  description = "Map of DNS Firewall cluster IDs, keyed as in var.dns_firewalls."
  value       = { for k, v in cloudflare_dns_firewall.this : k => v.id }
}

output "dns_firewall_ips" {
  description = "Map of the resolver IPs Cloudflare assigned to each DNS Firewall cluster, keyed as in var.dns_firewalls."
  value       = { for k, v in cloudflare_dns_firewall.this : k => v.dns_firewall_ips }
}
