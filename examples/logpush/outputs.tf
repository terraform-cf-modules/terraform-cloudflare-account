output "job_ids" {
  description = "IDs of the created Logpush jobs."
  value       = module.this.job_ids
}

output "ownership_challenge_filenames" {
  description = "Challenge file names Cloudflare wrote to each destination."
  value       = module.this.ownership_challenge_filenames
  sensitive   = true
}

output "logpull_retention" {
  description = "Created cloudflare_logpull_retention resources."
  value       = module.this.logpull_retention
}
