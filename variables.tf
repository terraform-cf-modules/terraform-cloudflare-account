# -----------------------------------------------------------------------------
# Common inputs. Every module in this organisation exposes these.
# -----------------------------------------------------------------------------

variable "enabled" {
  description = "Whether to create the resources managed by this module. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the resources. Required for account scoped resources, and ignored when var.create_account is true."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }

  validation {
    condition     = !var.enabled || var.create_account || var.account_id != null
    error_message = "account_id is required unless create_account is true."
  }
}

# -----------------------------------------------------------------------------
# The account itself
# -----------------------------------------------------------------------------

variable "create_account" {
  description = <<-EOT
    Whether to create the Cloudflare account (`cloudflare_account`). Creating accounts through the API requires a
    tenant or reseller relationship, so most callers leave this false and pass an existing `var.account_id`.
  EOT

  type    = bool
  default = false
}

variable "account_name" {
  description = "Name of the account to create. Required when var.create_account is true."
  type        = string
  default     = null

  validation {
    condition     = !var.create_account || var.account_name != null
    error_message = "account_name is required when create_account is true."
  }
}

variable "account_settings" {
  description = "Account settings. `enforce_twofactor` requires every member to have Two-Factor Authentication enabled."
  type = object({
    abuse_contact_email = optional(string)
    enforce_twofactor   = optional(bool)
  })
  default = null

  validation {
    condition = var.account_settings == null || try(var.account_settings.abuse_contact_email, null) == null || can(
      regex("^[^@[:space:]]+@[^@[:space:]]+$", coalesce(try(var.account_settings.abuse_contact_email, null), "a@b"))
    )
    error_message = "account_settings.abuse_contact_email must be a valid email address."
  }
}

variable "account_unit_id" {
  description = "Tenant unit ID to create the account under. Only meaningful for tenant and reseller relationships."
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Members and groups, handed to modules/member
# -----------------------------------------------------------------------------

variable "members" {
  description = <<-EOT
    Account members to invite, keyed by a stable identifier. Supply either `roles` (a set of Cloudflare role IDs)
    or `policies`, not both.
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
      for m in values(var.members) : can(regex("^[^@[:space:]]+@[^@[:space:]]+$", m.email))
    ])
    error_message = "Each member email must be a valid email address."
  }
}

variable "groups" {
  description = "User groups to create, keyed by a stable identifier."
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
    Membership of user groups, keyed by a stable identifier. Reference a group by `group_key` (a key of
    `var.groups`) or by `user_group_id`, and members by `member_keys` (keys of `var.members`) or `member_ids`.
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
      for g in values(var.group_members) : (g.group_key == null) != (g.user_group_id == null)
    ])
    error_message = "Each group_members entry must set exactly one of group_key or user_group_id."
  }
}

# -----------------------------------------------------------------------------
# Notifications, handed to modules/notification
# -----------------------------------------------------------------------------

variable "notification_webhooks" {
  description = "Webhook destinations for notification policies, keyed by a stable identifier. Sensitive because it carries the cf-webhook-auth secret."
  type = map(object({
    name   = string
    url    = string
    secret = optional(string)
  }))
  default   = {}
  sensitive = true

  validation {
    condition = alltrue([
      for w in values(var.notification_webhooks) : can(regex("^https://", w.url))
    ])
    error_message = "Each webhook url must be an https endpoint."
  }
}

variable "notification_policies" {
  description = <<-EOT
    Baseline notification policies, keyed by a stable identifier. Every policy needs at least one delivery
    mechanism. `webhook_keys` reference keys of `var.notification_webhooks`.
  EOT

  type = map(object({
    name           = string
    alert_type     = string
    description    = optional(string)
    enabled        = optional(bool, true)
    alert_interval = optional(string)
    emails         = optional(list(string), [])
    pagerduty_ids  = optional(list(string), [])
    webhook_keys   = optional(list(string), [])
    webhook_ids    = optional(list(string), [])
    filters = optional(object({
      actions                         = optional(list(string))
      affected_asns                   = optional(list(string))
      affected_components             = optional(list(string))
      affected_locations              = optional(list(string))
      airport_code                    = optional(list(string))
      alert_trigger_preferences       = optional(list(string))
      alert_trigger_preferences_value = optional(list(string))
      enabled                         = optional(list(string))
      environment                     = optional(list(string))
      event                           = optional(list(string))
      event_source                    = optional(list(string))
      event_type                      = optional(list(string))
      group_by                        = optional(list(string))
      health_check_id                 = optional(list(string))
      incident_impact                 = optional(list(string))
      input_id                        = optional(list(string))
      insight_class                   = optional(list(string))
      limit                           = optional(list(string))
      logo_tag                        = optional(list(string))
      megabits_per_second             = optional(list(string))
      new_health                      = optional(list(string))
      new_status                      = optional(list(string))
      packets_per_second              = optional(list(string))
      pool_id                         = optional(list(string))
      pop_names                       = optional(list(string))
      product                         = optional(list(string))
      project_id                      = optional(list(string))
      protocol                        = optional(list(string))
      query_tag                       = optional(list(string))
      requests_per_second             = optional(list(string))
      selectors                       = optional(list(string))
      services                        = optional(list(string))
      slo                             = optional(list(string))
      status                          = optional(list(string))
      target_hostname                 = optional(list(string))
      target_ip                       = optional(list(string))
      target_zone_name                = optional(list(string))
      traffic_exclusions              = optional(list(string))
      tunnel_id                       = optional(list(string))
      tunnel_name                     = optional(list(string))
      type                            = optional(list(string))
      where                           = optional(list(string))
      zones                           = optional(list(string))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.notification_policies) :
      length(p.emails) + length(p.pagerduty_ids) + length(p.webhook_keys) + length(p.webhook_ids) > 0
    ])
    error_message = "Each notification policy needs at least one mechanism: emails, pagerduty_ids, webhook_keys, or webhook_ids."
  }

  validation {
    condition = alltrue([
      for p in values(var.notification_policies) : alltrue([
        for e in p.emails : can(regex("^[^@[:space:]]+@[^@[:space:]]+$", e))
      ])
    ])
    error_message = "Each notification policy email must be a valid email address."
  }

  validation {
    condition = alltrue([
      for p in values(var.notification_policies) : contains(
        [
          "abuse_report_alert",
          "access_custom_certificate_expiration_type",
          "advanced_ddos_attack_l4_alert",
          "advanced_ddos_attack_l7_alert",
          "advanced_http_alert_error",
          "bgp_hijack_notification",
          "billing_usage_alert",
          "block_notification_block_removed",
          "block_notification_new_block",
          "block_notification_review_rejected",
          "bot_traffic_basic_alert",
          "brand_protection_alert",
          "brand_protection_digest",
          "clickhouse_alert_fw_anomaly",
          "clickhouse_alert_fw_ent_anomaly",
          "cloudforce_one_request_notification",
          "cni_maintenance_notification",
          "custom_analytics",
          "custom_bot_detection_alert",
          "custom_ssl_certificate_event_type",
          "dedicated_ssl_certificate_event_type",
          "device_connectivity_anomaly_alert",
          "dos_attack_l4",
          "dos_attack_l7",
          "expiring_service_token_alert",
          "failing_logpush_job_disabled_alert",
          "fbm_auto_advertisement",
          "fbm_dosd_attack",
          "fbm_volumetric_attack",
          "health_check_status_notification",
          "hostname_aop_custom_certificate_expiration_type",
          "http_alert_edge_error",
          "http_alert_origin_error",
          "image_notification",
          "image_resizing_notification",
          "incident_alert",
          "load_balancing_health_alert",
          "load_balancing_pool_enablement_alert",
          "logo_match_alert",
          "magic_tunnel_health_check_event",
          "magic_wan_tunnel_health",
          "maintenance_event_notification",
          "mtls_certificate_store_certificate_expiration_type",
          "pages_event_alert",
          "radar_notification",
          "real_origin_monitoring",
          "scriptmonitor_alert_new_code_change_detections",
          "scriptmonitor_alert_new_hosts",
          "scriptmonitor_alert_new_malicious_hosts",
          "scriptmonitor_alert_new_malicious_scripts",
          "scriptmonitor_alert_new_malicious_url",
          "scriptmonitor_alert_new_max_length_resource_url",
          "scriptmonitor_alert_new_resources",
          "secondary_dns_all_primaries_failing",
          "secondary_dns_primaries_failing",
          "secondary_dns_warning",
          "secondary_dns_zone_successfully_updated",
          "secondary_dns_zone_validation_warning",
          "security_insights_alert",
          "sentinel_alert",
          "stream_live_notifications",
          "synthetic_test_latency_alert",
          "synthetic_test_low_availability_alert",
          "traffic_anomalies_alert",
          "tunnel_health_event",
          "tunnel_update_event",
          "universal_ssl_event_type",
          "web_analytics_metrics_update",
          "zone_aop_custom_certificate_expiration_type",
      ], p.alert_type)
    ])
    error_message = "alert_type must be one of the Cloudflare notification alert types. See https://developers.cloudflare.com/notifications/ for the current list."
  }
}
