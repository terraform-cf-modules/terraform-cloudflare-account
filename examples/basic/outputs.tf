output "module" {
  description = "All outputs of the module under test."
  value       = module.this
  sensitive   = true
}

output "member_ids" {
  description = "IDs of the invited account members."
  value       = module.this.member_ids
}
