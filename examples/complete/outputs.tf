output "module" {
  description = "All outputs of the root module under test."
  value       = module.this
  sensitive   = true
}

output "account_id" {
  description = "Account ID everything is anchored on."
  value       = module.this.account_id
}

output "member_ids" {
  description = "IDs of the invited account members."
  value       = module.this.member_ids
}

output "group_ids" {
  description = "IDs of the created user groups."
  value       = module.this.group_ids
}

output "notification_policy_ids" {
  description = "IDs of the created notification policies."
  value       = module.this.notification_policy_ids
}

output "account_token_ids" {
  description = "IDs of the created account scoped API tokens."
  value       = module.api_token.account_token_ids
}

output "account_token_values" {
  description = "Secret values of the created account scoped API tokens."
  value       = module.api_token.account_token_values
  sensitive   = true
}

output "dns_firewall_ids" {
  description = "IDs of the created DNS Firewall clusters."
  value       = module.dns_settings.dns_firewall_ids
}

output "logpush_job_ids" {
  description = "IDs of the created Logpush jobs."
  value       = module.logpush.job_ids
}

output "secret_ids" {
  description = "IDs of the created secrets store secrets."
  value       = module.secrets_store.secret_ids
}

output "share_ids" {
  description = "IDs of the created shares."
  value       = module.sharing.share_ids
}
