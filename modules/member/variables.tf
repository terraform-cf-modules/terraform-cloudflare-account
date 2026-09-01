variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the members and user groups."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "members" {
  description = <<-EOT
    Account members to invite, keyed by a stable identifier.

    Supply either `roles` (a set of Cloudflare role IDs) or `policies`, not both. The Cloudflare API rejects a
    member that carries legacy roles and scoped policies at the same time.
  EOT

  type = map(object({
    email  = string
    roles  = optional(set(string))
    status = optional(string)
    policies = optional(list(object({
      access               = string
      permission_group_ids = list(string)
      resource_group_ids   = list(string)
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for m in values(var.members) :
      m.status == null || contains(["accepted", "pending"], coalesce(m.status, "pending"))
    ])
    error_message = "Each member status must be one of accepted, pending."
  }

  validation {
    condition = alltrue([
      for m in values(var.members) : alltrue([
        for p in coalesce(m.policies, []) : contains(["allow", "deny"], p.access)
      ])
    ])
    error_message = "Each member policy access must be one of allow, deny."
  }

  validation {
    condition = alltrue([
      for m in values(var.members) :
      !(m.roles != null && length(m.roles) > 0 && m.policies != null && length(m.policies) > 0)
    ])
    error_message = "A member may set roles or policies, but not both."
  }

  validation {
    condition = alltrue([
      for m in values(var.members) : can(regex("^[^@[:space:]]+@[^@[:space:]]+$", m.email))
    ])
    error_message = "Each member email must be a valid email address."
  }
}

variable "groups" {
  description = "User groups to create, keyed by a stable identifier. Policies grant the group its permissions."
  type = map(object({
    name = string
    policies = optional(list(object({
      access               = string
      permission_group_ids = list(string)
      resource_group_ids   = list(string)
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for g in values(var.groups) : alltrue([
        for p in coalesce(g.policies, []) : contains(["allow", "deny"], p.access)
      ])
    ])
    error_message = "Each group policy access must be one of allow, deny."
  }
}

variable "group_members" {
  description = <<-EOT
    Membership of user groups, keyed by a stable identifier.

    Reference a group either by `group_key` (a key of `var.groups`) or by `user_group_id` for a group this module
    does not manage. Reference members either by `member_keys` (keys of `var.members`) or by `member_ids`.
  EOT

  type = map(object({
    group_key     = optional(string)
    user_group_id = optional(string)
    member_keys   = optional(list(string), [])
    member_ids    = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for g in values(var.group_members) :
      (g.group_key == null) != (g.user_group_id == null)
    ])
    error_message = "Each group_members entry must set exactly one of group_key or user_group_id."
  }

  validation {
    condition = alltrue([
      for g in values(var.group_members) :
      length(g.member_keys) + length(g.member_ids) > 0
    ])
    error_message = "Each group_members entry must reference at least one member through member_keys or member_ids."
  }
}
