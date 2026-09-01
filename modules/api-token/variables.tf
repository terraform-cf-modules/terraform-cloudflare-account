variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the account scoped tokens. Required when var.account_tokens is not empty."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "user_tokens" {
  description = <<-EOT
    User scoped API tokens (`cloudflare_api_token`), keyed by a stable identifier.

    `policies` is a map keyed by a stable identifier so that adding or removing a policy does not shift the
    others. Each policy needs `permission_group_ids` and one of `resources` (a map of resource scope to value,
    encoded to JSON for you) or `resources_json` (a raw JSON string for scopes the map form cannot express).

    The generated token value is available on the `user_token_values` output and is marked sensitive.
  EOT

  type = map(object({
    name              = string
    status            = optional(string)
    expires_on        = optional(string)
    not_before        = optional(string)
    request_ip_in     = optional(list(string))
    request_ip_not_in = optional(list(string))
    policies = map(object({
      effect               = optional(string, "allow")
      permission_group_ids = list(string)
      resources            = optional(map(string))
      resources_json       = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in values(var.user_tokens) :
      t.status == null || contains(["active", "disabled", "expired"], coalesce(t.status, "active"))
    ])
    error_message = "Each user token status must be one of active, disabled, expired."
  }

  validation {
    condition = alltrue([
      for t in values(var.user_tokens) : alltrue([
        for p in values(t.policies) : contains(["allow", "deny"], p.effect)
      ])
    ])
    error_message = "Each token policy effect must be one of allow, deny."
  }

  validation {
    condition = alltrue([
      for t in values(var.user_tokens) : alltrue([
        for p in values(t.policies) : (p.resources == null) != (p.resources_json == null)
      ])
    ])
    error_message = "Each token policy must set exactly one of resources or resources_json."
  }

  validation {
    condition = alltrue([
      for t in values(var.user_tokens) : length(t.policies) > 0
    ])
    error_message = "Each user token must declare at least one policy."
  }
}

variable "account_tokens" {
  description = <<-EOT
    Account scoped API tokens (`cloudflare_account_token`), keyed by a stable identifier. Same shape as
    `var.user_tokens`. The generated token value is available on the `account_token_values` output and is marked
    sensitive.
  EOT

  type = map(object({
    name              = string
    status            = optional(string)
    expires_on        = optional(string)
    not_before        = optional(string)
    request_ip_in     = optional(list(string))
    request_ip_not_in = optional(list(string))
    policies = map(object({
      effect               = optional(string, "allow")
      permission_group_ids = list(string)
      resources            = optional(map(string))
      resources_json       = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in values(var.account_tokens) :
      t.status == null || contains(["active", "disabled", "expired"], coalesce(t.status, "active"))
    ])
    error_message = "Each account token status must be one of active, disabled, expired."
  }

  validation {
    condition = alltrue([
      for t in values(var.account_tokens) : alltrue([
        for p in values(t.policies) : contains(["allow", "deny"], p.effect)
      ])
    ])
    error_message = "Each token policy effect must be one of allow, deny."
  }

  validation {
    condition = alltrue([
      for t in values(var.account_tokens) : alltrue([
        for p in values(t.policies) : (p.resources == null) != (p.resources_json == null)
      ])
    ])
    error_message = "Each token policy must set exactly one of resources or resources_json."
  }

  validation {
    condition = alltrue([
      for t in values(var.account_tokens) : length(t.policies) > 0
    ])
    error_message = "Each account token must declare at least one policy."
  }
}
