variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the shares. This is the sending side of the share."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "shares" {
  description = <<-EOT
    Shares (`cloudflare_share`), keyed by a stable identifier.

    A share is created with its initial recipients and resources inline. Recipients and resources added later
    are separate resources: see `var.recipients` and `var.resources`.

    Each recipient sets exactly one of `recipient_account_id` or `organization_id`.
  EOT

  type = map(object({
    name = string
    recipients = list(object({
      recipient_account_id = optional(string)
      organization_id      = optional(string)
    }))
    resources = list(object({
      resource_id         = string
      resource_type       = string
      resource_account_id = string
      meta                = optional(string, "{}")
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in values(var.shares) : alltrue([
        for r in s.recipients : (r.recipient_account_id == null) != (r.organization_id == null)
      ])
    ])
    error_message = "Each share recipient must set exactly one of recipient_account_id or organization_id."
  }

  validation {
    condition = alltrue([
      for s in values(var.shares) : alltrue([
        for r in s.resources : contains([
          "custom-ruleset",
          "gateway-policy",
          "gateway-destination-ip",
          "gateway-block-page-settings",
          "gateway-extended-email-matching",
          "idp-federation-grant",
        ], r.resource_type)
      ])
    ])
    error_message = "Each share resource_type must be one of custom-ruleset, gateway-policy, gateway-destination-ip, gateway-block-page-settings, gateway-extended-email-matching, idp-federation-grant."
  }

  validation {
    condition = alltrue([
      for s in values(var.shares) : alltrue([
        for r in s.resources : can(jsondecode(r.meta))
      ])
    ])
    error_message = "Each share resource meta must be a JSON encoded object."
  }
}

variable "recipients" {
  description = <<-EOT
    Extra recipients added to an existing share (`cloudflare_share_recipient`), keyed by a stable identifier.

    Reference the share either by `share_key` (a key of `var.shares`) or by `share_id`.
  EOT

  type = map(object({
    share_key            = optional(string)
    share_id             = optional(string)
    recipient_account_id = optional(string)
    organization_id      = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.recipients) : (r.share_key == null) != (r.share_id == null)
    ])
    error_message = "Each recipient must set exactly one of share_key or share_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.recipients) : (r.recipient_account_id == null) != (r.organization_id == null)
    ])
    error_message = "Each recipient must set exactly one of recipient_account_id or organization_id."
  }
}

variable "resources" {
  description = <<-EOT
    Extra resources added to an existing share (`cloudflare_share_resource`), keyed by a stable identifier.

    Reference the share either by `share_key` (a key of `var.shares`) or by `share_id`.
  EOT

  type = map(object({
    share_key           = optional(string)
    share_id            = optional(string)
    resource_id         = string
    resource_type       = string
    resource_account_id = string
    meta                = optional(string, "{}")
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.resources) : (r.share_key == null) != (r.share_id == null)
    ])
    error_message = "Each shared resource must set exactly one of share_key or share_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.resources) : contains([
        "custom-ruleset",
        "gateway-policy",
        "gateway-destination-ip",
        "gateway-block-page-settings",
        "gateway-extended-email-matching",
        "idp-federation-grant",
      ], r.resource_type)
    ])
    error_message = "Each shared resource_type must be one of custom-ruleset, gateway-policy, gateway-destination-ip, gateway-block-page-settings, gateway-extended-email-matching, idp-federation-grant."
  }

  validation {
    condition = alltrue([
      for r in values(var.resources) : can(jsondecode(r.meta))
    ])
    error_message = "Each shared resource meta must be a JSON encoded object."
  }
}
