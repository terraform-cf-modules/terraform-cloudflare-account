output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "user_tokens" {
  description = "Map of created cloudflare_api_token resources, keyed as in var.user_tokens. Contains the token value."
  value       = cloudflare_api_token.this
  sensitive   = true
}

output "user_token_ids" {
  description = "Map of user API token IDs, keyed as in var.user_tokens."
  value       = { for k, v in cloudflare_api_token.this : k => v.id }
}

output "user_token_values" {
  description = "Map of user API token secret values, keyed as in var.user_tokens. Disclosed by the API only on creation."
  value       = { for k, v in cloudflare_api_token.this : k => v.value }
  sensitive   = true
}

output "account_tokens" {
  description = "Map of created cloudflare_account_token resources, keyed as in var.account_tokens. Contains the token value."
  value       = cloudflare_account_token.this
  sensitive   = true
}

output "account_token_ids" {
  description = "Map of account API token IDs, keyed as in var.account_tokens."
  value       = { for k, v in cloudflare_account_token.this : k => v.id }
}

output "account_token_values" {
  description = "Map of account API token secret values, keyed as in var.account_tokens. Disclosed by the API only on creation."
  value       = { for k, v in cloudflare_account_token.this : k => v.value }
  sensitive   = true
}
