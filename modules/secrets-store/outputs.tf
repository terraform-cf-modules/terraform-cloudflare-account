output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "stores" {
  description = "Map of created cloudflare_secrets_store resources, keyed as in var.stores."
  value       = cloudflare_secrets_store.this
}

output "store_ids" {
  description = "Map of secrets store IDs, keyed as in var.stores."
  value       = { for k, v in cloudflare_secrets_store.this : k => v.id }
}

output "secrets" {
  description = "Map of created cloudflare_secrets_store_secret resources, keyed as in var.secrets. Sensitive because it carries the secret value."
  value       = cloudflare_secrets_store_secret.this
  sensitive   = true
}

output "secret_ids" {
  description = "Map of secret IDs, keyed as in var.secrets."
  value       = { for k, v in cloudflare_secrets_store_secret.this : k => v.id }
}
