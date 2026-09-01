variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "zone_id" {
  description = "Cloudflare zone ID for the zone scoped job."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "destination_conf" {
  description = <<-EOT
    Logpush sink URL. This usually embeds a credential, for example
    `s3://bucket/logs?region=eu-west-1&access-key-id=...&secret-access-key=...`.
    Supply it through TF_VAR_destination_conf and keep it out of version control.
  EOT

  type      = string
  default   = "s3://example-bucket/logs?region=eu-west-1"
  sensitive = true
}
