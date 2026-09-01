output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "members" {
  description = "Map of created cloudflare_account_member resources, keyed as in var.members."
  value       = cloudflare_account_member.this
}

output "member_ids" {
  description = "Map of account member IDs, keyed as in var.members."
  value       = { for k, v in cloudflare_account_member.this : k => v.id }
}

output "groups" {
  description = "Map of created cloudflare_user_group resources, keyed as in var.groups."
  value       = cloudflare_user_group.this
}

output "group_ids" {
  description = "Map of user group IDs, keyed as in var.groups."
  value       = { for k, v in cloudflare_user_group.this : k => v.id }
}

output "group_members" {
  description = "Map of created cloudflare_user_group_members resources, keyed as in var.group_members."
  value       = cloudflare_user_group_members.this
}

output "group_member_ids" {
  description = "Map of user group membership IDs, keyed as in var.group_members."
  value       = { for k, v in cloudflare_user_group_members.this : k => v.id }
}
