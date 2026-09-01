# Logpush, which has two non obvious properties.
#
# 1. destination_conf carries credentials. For S3, GCS, Azure Blob, Splunk and
#    friends the access key or signed token is part of the URL. The provider
#    marks the attribute SENSITIVE, this module marks the whole `jobs` and
#    `ownership_challenges` inputs sensitive, and every output that can carry it
#    is sensitive too. It still lands in Terraform state, so treat state as a
#    secret and never commit the value.
#
# 2. A destination must prove ownership before a job can write to it. Cloudflare
#    drops a challenge file in the destination; the token inside it goes back as
#    the job's ownership_challenge. Create the challenge here and reference it by
#    key, and the dependency is expressed for you.
#
# Scope: a job is either account scoped or zone scoped, never both. Set zone_id
# on the entry (or account_scoped = false with a module level zone_id) for a zone
# scoped job.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../modules/logpush"

  enabled    = true
  account_id = var.account_id
  zone_id    = var.zone_id

  ownership_challenges = {
    audit_bucket = {
      destination_conf = var.destination_conf
    }
  }

  jobs = {
    # Account scoped: audit logs for the whole account.
    audit_logs = {
      dataset                 = "audit_logs"
      destination_conf        = var.destination_conf
      name                    = "audit-logs"
      ownership_challenge_key = "audit_bucket"

      max_upload_bytes            = 5000000
      max_upload_interval_seconds = 60
      max_upload_records          = 10000

      output_options = {
        output_type      = "ndjson"
        timestamp_format = "rfc3339"
        field_names      = ["ActorEmail", "ActionType", "When", "ResourceType"]

        # Neutralise the log4shell payload shape in generated files.
        cve_2021_44228 = true
      }
    }

    # Zone scoped: only requests that got a 4xx or 5xx at the edge.
    edge_errors = {
      dataset          = "http_requests"
      destination_conf = var.destination_conf
      name             = "edge-errors"
      zone_id          = var.zone_id

      filter = jsonencode({
        where = {
          and = [{ key = "EdgeResponseStatus", operator = "gt", value = 399 }]
        }
      })

      output_options = {
        output_type = "csv"
        field_names = ["ClientIP", "EdgeResponseStatus", "RayID"]
      }
    }
  }

  logpull_retention = {
    primary_zone = {
      zone_id = var.zone_id
      flag    = true
    }
  }
}
