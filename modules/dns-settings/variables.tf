variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID whose DNS defaults and DNS Firewall clusters this submodule manages."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "create_dns_settings" {
  description = "Whether to manage the account level DNS settings (`cloudflare_account_dns_settings`). There is exactly one per account."
  type        = bool
  default     = false
}

variable "enforce_dns_only" {
  description = "Force every proxied DNS record in the account to be served DNS-only at the edge, without changing the records themselves."
  type        = bool
  default     = null
}

variable "zone_defaults" {
  description = <<-EOT
    Account wide defaults applied to newly created zones. Only used when `var.create_dns_settings` is true.
  EOT

  type = object({
    flatten_all_cnames  = optional(bool)
    foundation_dns      = optional(bool)
    multi_provider      = optional(bool)
    ns_ttl              = optional(number)
    secondary_overrides = optional(bool)
    zone_mode           = optional(string)
    internal_dns = optional(object({
      reference_zone_id = optional(string)
    }))
    nameservers = optional(object({
      type = optional(string)
    }))
    soa = optional(object({
      expire  = optional(number)
      min_ttl = optional(number)
      mname   = optional(string)
      refresh = optional(number)
      retry   = optional(number)
      rname   = optional(string)
      ttl     = optional(number)
    }))
  })
  default = null

  validation {
    condition = var.zone_defaults == null || var.zone_defaults.zone_mode == null || contains(
      ["standard", "cdn_only", "dns_only"], coalesce(try(var.zone_defaults.zone_mode, null), "standard")
    )
    error_message = "zone_defaults.zone_mode must be one of standard, cdn_only, dns_only."
  }

  validation {
    condition = var.zone_defaults == null || try(var.zone_defaults.nameservers, null) == null || try(var.zone_defaults.nameservers.type, null) == null || contains(
      ["cloudflare.standard", "cloudflare.standard.random", "custom.account", "custom.tenant"],
      coalesce(try(var.zone_defaults.nameservers.type, null), "cloudflare.standard")
    )
    error_message = "zone_defaults.nameservers.type must be one of cloudflare.standard, cloudflare.standard.random, custom.account, custom.tenant."
  }
}

variable "dns_firewalls" {
  description = <<-EOT
    DNS Firewall clusters (`cloudflare_dns_firewall`), keyed by a stable identifier.

    `dns_firewall_ip_count` is only read when the cluster is created and cannot be changed afterwards.
  EOT

  type = map(object({
    name                   = string
    upstream_ips           = set(string)
    deprecate_any_requests = optional(bool)
    dns_firewall_ip_count  = optional(number)
    ecs_fallback           = optional(bool)
    maximum_cache_ttl      = optional(number)
    minimum_cache_ttl      = optional(number)
    negative_cache_ttl     = optional(number)
    ratelimit              = optional(number)
    retries                = optional(number)
    attack_mitigation = optional(object({
      enabled                      = optional(bool)
      only_when_upstream_unhealthy = optional(bool)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for f in values(var.dns_firewalls) : length(f.upstream_ips) > 0
    ])
    error_message = "Each DNS Firewall cluster must list at least one upstream IP."
  }

  validation {
    condition = alltrue([
      for f in values(var.dns_firewalls) :
      f.minimum_cache_ttl == null || f.maximum_cache_ttl == null || f.minimum_cache_ttl <= f.maximum_cache_ttl
    ])
    error_message = "minimum_cache_ttl must not exceed maximum_cache_ttl."
  }
}
