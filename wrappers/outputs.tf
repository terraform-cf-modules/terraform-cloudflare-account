output "wrapper" {
  description = "Map of module outputs, keyed by the same keys as var.items."
  value       = module.wrapper
  sensitive   = true
}

output "account_ids" {
  description = "Map of the account ID each instance is anchored on, keyed as in var.items."
  value       = { for k, v in module.wrapper : k => v.account_id }
}
