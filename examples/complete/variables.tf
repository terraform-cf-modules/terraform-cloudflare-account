variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "recipient_account_id" {
  description = "Account that receives the share."
  type        = string
  default     = "11111111111111111111111111111111"
}

variable "second_recipient_account_id" {
  description = "Second account added to the share after creation."
  type        = string
  default     = "22222222222222222222222222222222"
}

variable "webhook_secret" {
  description = "Secret sent in the cf-webhook-auth header. Supply through TF_VAR_webhook_secret."
  type        = string
  default     = "replace-me"
  sensitive   = true
}

variable "logpush_destination_conf" {
  description = <<-EOT
    Logpush sink URL. For S3 and similar sinks this embeds an access key, so supply it through
    TF_VAR_logpush_destination_conf rather than committing it.
  EOT

  type      = string
  default   = "s3://example-bucket/logs?region=eu-west-1"
  sensitive = true
}

variable "upstream_api_key" {
  description = "Secret material stored in the secrets store. Supply through TF_VAR_upstream_api_key."
  type        = string
  default     = "replace-me"
  sensitive   = true
}
