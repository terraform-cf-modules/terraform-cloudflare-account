output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "shares" {
  description = "Map of created cloudflare_share resources, keyed as in var.shares."
  value       = cloudflare_share.this
}

output "share_ids" {
  description = "Map of share IDs, keyed as in var.shares."
  value       = { for k, v in cloudflare_share.this : k => v.id }
}

output "recipients" {
  description = "Map of created cloudflare_share_recipient resources, keyed as in var.recipients."
  value       = cloudflare_share_recipient.this
}

output "resources" {
  description = "Map of created cloudflare_share_resource resources, keyed as in var.resources."
  value       = cloudflare_share_resource.this
}

output "recipient_ids" {
  description = "Map of share recipient IDs, keyed as in var.recipients."
  value       = { for k, v in cloudflare_share_recipient.this : k => v.id }
}

output "resource_ids" {
  description = "Map of shared resource IDs, keyed as in var.resources."
  value       = { for k, v in cloudflare_share_resource.this : k => v.id }
}
