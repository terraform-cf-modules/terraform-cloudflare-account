variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the secrets stores."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "stores" {
  description = "Secrets stores (`cloudflare_secrets_store`), keyed by a stable identifier."
  type = map(object({
    name = string
  }))
  default = {}
}

variable "secrets" {
  description = <<-EOT
    Secrets (`cloudflare_secrets_store_secret`), keyed by a stable identifier.

    **This variable is sensitive.** `value` is the secret material itself. Cloudflare never reads it back, so
    Terraform cannot detect drift on it, but it does live in Terraform state. Source it from a data source or a
    `TF_VAR_` environment variable rather than committing it.

    Reference the store either by `store_key` (a key of `var.stores`) or by `store_id` for a store this module
    does not manage. `scopes` must be listed in alphabetical order; Cloudflare rejects any other order.
  EOT

  type = map(object({
    name      = string
    value     = string
    scopes    = list(string)
    comment   = optional(string)
    store_key = optional(string)
    store_id  = optional(string)
  }))
  default   = {}
  sensitive = true

  validation {
    condition = alltrue([
      for s in values(var.secrets) : (s.store_key == null) != (s.store_id == null)
    ])
    error_message = "Each secret must set exactly one of store_key or store_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.secrets) : alltrue([
        for scope in s.scopes : contains(["access", "ai_gateway", "dex", "workers"], scope)
      ])
    ])
    error_message = "Each secret scope must be one of access, ai_gateway, dex, workers."
  }

  validation {
    condition = alltrue([
      for s in values(var.secrets) : s.scopes == sort(s.scopes) && length(s.scopes) > 0
    ])
    error_message = "Each secret must declare at least one scope and list its scopes in alphabetical order."
  }
}
