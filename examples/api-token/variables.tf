variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "zone_id" {
  description = "Cloudflare zone ID the CI token may edit DNS in."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "dns_write_permission_group_id" {
  description = "Permission group ID for DNS write. Read the real value from GET /accounts/{account_id}/tokens/permission_groups."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "analytics_read_permission_group_id" {
  description = "Permission group ID for analytics read."
  type        = string
  default     = "11111111111111111111111111111111"
}
