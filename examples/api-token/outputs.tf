output "account_token_ids" {
  description = "IDs of the created account scoped tokens."
  value       = module.this.account_token_ids
}

output "user_token_ids" {
  description = "IDs of the created user scoped tokens."
  value       = module.this.user_token_ids
}

output "account_token_values" {
  description = "Secret values of the created account scoped tokens. Disclosed by the API only on creation."
  value       = module.this.account_token_values
  sensitive   = true
}

output "user_token_values" {
  description = "Secret values of the created user scoped tokens. Disclosed by the API only on creation."
  value       = module.this.user_token_values
  sensitive   = true
}
