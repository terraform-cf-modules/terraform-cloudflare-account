output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "jobs" {
  description = "Map of created cloudflare_logpush_job resources, keyed as in var.jobs. Sensitive because destination_conf can embed credentials."
  value       = cloudflare_logpush_job.this
  sensitive   = true
}

output "job_ids" {
  description = "Map of Logpush job IDs, keyed as in var.jobs."
  value       = { for k, v in cloudflare_logpush_job.this : k => v.id }
}

output "ownership_challenges" {
  description = "Map of created cloudflare_logpush_ownership_challenge resources, keyed as in var.ownership_challenges."
  value       = cloudflare_logpush_ownership_challenge.this
  sensitive   = true
}

output "ownership_challenge_filenames" {
  description = "Map of the challenge file names Cloudflare wrote to each destination, keyed as in var.ownership_challenges."
  value       = { for k, v in cloudflare_logpush_ownership_challenge.this : k => v.filename }
  sensitive   = true
}

output "logpull_retention" {
  description = "Map of created cloudflare_logpull_retention resources, keyed as in var.logpull_retention."
  value       = cloudflare_logpull_retention.this
}

output "logpull_retention_ids" {
  description = "Map of Logpull retention resource IDs, keyed as in var.logpull_retention."
  value       = { for k, v in cloudflare_logpull_retention.this : k => v.id }
}
