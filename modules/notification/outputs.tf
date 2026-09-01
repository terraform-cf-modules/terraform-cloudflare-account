output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "webhooks" {
  description = "Map of created cloudflare_notification_policy_webhooks resources, keyed as in var.webhooks."
  value       = cloudflare_notification_policy_webhooks.this
  sensitive   = true
}

output "webhook_ids" {
  description = "Map of webhook destination IDs, keyed as in var.webhooks."
  value       = { for k, v in cloudflare_notification_policy_webhooks.this : k => v.id }
}

output "policies" {
  description = "Map of created cloudflare_notification_policy resources, keyed as in var.policies."
  value       = cloudflare_notification_policy.this
}

output "policy_ids" {
  description = "Map of notification policy IDs, keyed as in var.policies."
  value       = { for k, v in cloudflare_notification_policy.this : k => v.id }
}
