output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}

output "account_id" {
  description = "Account ID everything in this module is anchored on. The created account when var.create_account is true, otherwise var.account_id."
  value       = local.account_id
}

output "account" {
  description = "The cloudflare_account resource, or null when the account was not created by this module."
  value       = one(cloudflare_account.this)
}

output "members" {
  description = "Map of created cloudflare_account_member resources, keyed as in var.members."
  value       = module.member.members
}

output "member_ids" {
  description = "Map of account member IDs, keyed as in var.members."
  value       = module.member.member_ids
}

output "groups" {
  description = "Map of created cloudflare_user_group resources, keyed as in var.groups."
  value       = module.member.groups
}

output "group_ids" {
  description = "Map of user group IDs, keyed as in var.groups."
  value       = module.member.group_ids
}

output "group_members" {
  description = "Map of created cloudflare_user_group_members resources, keyed as in var.group_members."
  value       = module.member.group_members
}

output "notification_webhooks" {
  description = "Map of created webhook destinations, keyed as in var.notification_webhooks. Sensitive because it carries the webhook secret."
  value       = module.notification.webhooks
  sensitive   = true
}

output "notification_webhook_ids" {
  description = "Map of webhook destination IDs, keyed as in var.notification_webhooks."
  value       = module.notification.webhook_ids
}

output "notification_policies" {
  description = "Map of created cloudflare_notification_policy resources, keyed as in var.notification_policies."
  value       = module.notification.policies
}

output "notification_policy_ids" {
  description = "Map of notification policy IDs, keyed as in var.notification_policies."
  value       = module.notification.policy_ids
}

output "group_member_ids" {
  description = "Map of user group membership IDs, keyed as in var.group_members."
  value       = module.member.group_member_ids
}
