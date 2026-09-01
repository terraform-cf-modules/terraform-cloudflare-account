# Every optional feature of the Cloudflare Account module turned on.
#
# The root module handles the account, its people, and the baseline alerts. The
# remaining building blocks are called directly so the example shows the full
# surface of the repository.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

locals {
  # Placeholder IDs so the example plans without credentials. Replace them with
  # real permission group, resource group, and role IDs from your account.
  placeholder_id = "00000000000000000000000000000000"
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id

  # Set create_account = true and account_name only if you hold a tenant or
  # reseller relationship with Cloudflare. Most callers pass an existing account.
  create_account = false

  members = {
    platform_lead = {
      email  = "platform@example.com"
      roles  = [local.placeholder_id]
      status = "pending"
    }

    auditor = {
      email = "audit@example.com"
      policies = [{
        access               = "allow"
        permission_group_ids = [local.placeholder_id]
        resource_group_ids   = [local.placeholder_id]
      }]
    }
  }

  groups = {
    network_engineers = {
      name = "Network engineers"
      policies = [{
        access               = "allow"
        permission_group_ids = [local.placeholder_id]
        resource_group_ids   = [local.placeholder_id]
      }]
    }
  }

  group_members = {
    network_engineers = {
      group_key   = "network_engineers"
      member_keys = ["platform_lead"]
    }
  }

  notification_webhooks = {
    ops_channel = {
      name   = "Ops channel"
      url    = "https://hooks.example.com/cloudflare"
      secret = var.webhook_secret
    }
  }

  notification_policies = {
    origin_errors = {
      name         = "Origin error rate"
      alert_type   = "http_alert_origin_error"
      description  = "Fires when origin 5xx rate crosses the configured threshold."
      emails       = ["platform@example.com"]
      webhook_keys = ["ops_channel"]

      filters = {
        zones = [var.zone_id]
      }
    }

    ddos_l7 = {
      name           = "Advanced L7 DDoS"
      alert_type     = "advanced_ddos_attack_l7_alert"
      alert_interval = "1h"
      webhook_keys   = ["ops_channel"]
    }
  }
}

module "api_token" {
  source = "../../modules/api-token"

  enabled    = true
  account_id = var.account_id

  account_tokens = {
    dns_editor = {
      name   = "dns-editor"
      status = "active"

      policies = {
        dns_write = {
          effect               = "allow"
          permission_group_ids = [local.placeholder_id]
          resources = {
            "com.cloudflare.api.account.zone.${var.zone_id}" = "*"
          }
        }
      }
    }
  }

  user_tokens = {
    read_only = {
      name              = "read-only"
      request_ip_in     = ["203.0.113.0/24"]
      request_ip_not_in = ["203.0.113.42/32"]

      policies = {
        analytics_read = {
          effect               = "allow"
          permission_group_ids = [local.placeholder_id]
          resources = {
            "com.cloudflare.api.account.${var.account_id}" = "*"
          }
        }
      }
    }
  }
}

module "dns_settings" {
  source = "../../modules/dns-settings"

  enabled    = true
  account_id = var.account_id

  create_dns_settings = true
  enforce_dns_only    = false

  zone_defaults = {
    flatten_all_cnames = false
    ns_ttl             = 86400
    zone_mode          = "standard"

    nameservers = {
      type = "cloudflare.standard"
    }

    soa = {
      expire  = 604800
      min_ttl = 1800
      refresh = 10000
      retry   = 2400
      ttl     = 3600
      mname   = "ns1.example.com"
      rname   = "hostmaster.example.com"
    }
  }

  dns_firewalls = {
    corp_resolver = {
      name                   = "corp-resolver"
      upstream_ips           = ["203.0.113.10", "203.0.113.11"]
      deprecate_any_requests = true
      ecs_fallback           = false
      minimum_cache_ttl      = 60
      maximum_cache_ttl      = 900
      negative_cache_ttl     = 60
      ratelimit              = 600
      retries                = 2

      attack_mitigation = {
        enabled                      = true
        only_when_upstream_unhealthy = false
      }
    }
  }
}

module "logpush" {
  source = "../../modules/logpush"

  enabled    = true
  account_id = var.account_id
  zone_id    = var.zone_id

  ownership_challenges = {
    audit_bucket = {
      destination_conf = var.logpush_destination_conf
    }
  }

  jobs = {
    audit_logs = {
      dataset                     = "audit_logs"
      destination_conf            = var.logpush_destination_conf
      name                        = "audit-logs"
      ownership_challenge_key     = "audit_bucket"
      max_upload_interval_seconds = 60
      max_upload_records          = 10000

      output_options = {
        output_type      = "ndjson"
        timestamp_format = "rfc3339"
        field_names      = ["ActorEmail", "ActionType", "When"]
        cve_2021_44228   = true
      }
    }

    http_requests = {
      dataset          = "http_requests"
      destination_conf = var.logpush_destination_conf
      name             = "http-requests"
      account_scoped   = false
      zone_id          = var.zone_id
      filter           = jsonencode({ where = { and = [{ key = "EdgeResponseStatus", operator = "gt", value = 399 }] } })
    }
  }

  logpull_retention = {
    primary_zone = {
      zone_id = var.zone_id
      flag    = true
    }
  }
}

module "secrets_store" {
  source = "../../modules/secrets-store"

  enabled    = true
  account_id = var.account_id

  stores = {
    platform = {
      name = "platform"
    }
  }

  secrets = {
    upstream_api_key = {
      name      = "UPSTREAM_API_KEY"
      value     = var.upstream_api_key
      scopes    = ["workers"]
      comment   = "Key the edge worker presents to the upstream API."
      store_key = "platform"
    }
  }
}

module "sharing" {
  source = "../../modules/sharing"

  enabled    = true
  account_id = var.account_id

  shares = {
    gateway_baseline = {
      name = "gateway-baseline"

      recipients = [{
        recipient_account_id = var.recipient_account_id
      }]

      resources = [{
        resource_id         = local.placeholder_id
        resource_type       = "gateway-policy"
        resource_account_id = var.account_id
        meta                = jsonencode({ description = "Shared block list" })
      }]
    }
  }

  recipients = {
    second_account = {
      share_key            = "gateway_baseline"
      recipient_account_id = var.second_recipient_account_id
    }
  }

  resources = {
    extra_ruleset = {
      share_key           = "gateway_baseline"
      resource_id         = local.placeholder_id
      resource_type       = "custom-ruleset"
      resource_account_id = var.account_id
      meta                = jsonencode({ description = "Shared WAF ruleset" })
    }
  }
}
