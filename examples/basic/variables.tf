variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "administrator_role_id" {
  description = "Cloudflare account role ID to grant the member. Read the real IDs from the account roles API."
  type        = string
  default     = "00000000000000000000000000000000"
}
