variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the notification policies and webhook destinations."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "webhooks" {
  description = <<-EOT
    Webhook destinations (`cloudflare_notification_policy_webhooks`), keyed by a stable identifier.

    `secret` is passed in the `cf-webhook-auth` header. Cloudflare never returns it, so Terraform cannot detect
    drift on it.
  EOT

  type = map(object({
    name   = string
    url    = string
    secret = optional(string)
  }))
  default   = {}
  sensitive = true

  validation {
    condition = alltrue([
      for w in values(var.webhooks) : can(regex("^https://", w.url))
    ])
    error_message = "Each webhook url must be an https endpoint."
  }
}

variable "policies" {
  description = <<-EOT
    Notification policies (`cloudflare_notification_policy`), keyed by a stable identifier.

    Every policy needs at least one delivery mechanism. `emails` are plain addresses, `pagerduty_ids` are
    connected PagerDuty service IDs, `webhook_keys` reference keys of `var.webhooks`, and `webhook_ids` reference
    webhook destinations this module does not manage.

    `filters` narrows an alert to a subset of events. Which fields apply depends entirely on `alert_type`; see
    the Cloudflare alert reference.
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
      for p in values(var.policies) :
      length(p.emails) + length(p.pagerduty_ids) + length(p.webhook_keys) + length(p.webhook_ids) > 0
    ])
    error_message = "Each notification policy needs at least one mechanism: emails, pagerduty_ids, webhook_keys, or webhook_ids."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) : alltrue([
        for e in p.emails : can(regex("^[^@[:space:]]+@[^@[:space:]]+$", e))
      ])
    ])
    error_message = "Each notification policy email must be a valid email address."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) : contains(
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
