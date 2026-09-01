<!-- This file was automatically generated from `README.yaml`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->
<p align="center">
  <img width="1000" alt="CloudDrove Banner" src="https://clouddrove.s3.ca-central-1.amazonaws.com/img/clouddrove-github-cover.png" />
</p>
<h1 align="center">
    Terraform Cloudflare Account
</h1>

<p align="center" style="font-size: 1.2rem;">
    With our comprehensive DevOps toolkit, streamline operations, automate workflows, enhance collaboration and deploy with confidence.
</p>

<p align="center">

<a href="https://www.terraform.io">
  <img src="https://img.shields.io/badge/Terraform-v1.12.0-green" alt="Terraform">
</a>
<a href="LICENSE">
  <img src="https://img.shields.io/badge/License-APACHE-blue.svg" alt="Licence">
</a>
<a href="CHANGELOG.md">
  <img src="https://img.shields.io/badge/Changelog-blue" alt="Changelog">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/tf-checks.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/tf-checks.yml/badge.svg" alt="tf-checks">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/tflint.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/tflint.yml/badge.svg" alt="tf-lint">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/checkov.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/checkov.yml/badge.svg" alt="checkov">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/test.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-account/actions/workflows/test.yml/badge.svg" alt="test">
</a>

</p>
<hr>


Account level Cloudflare: the account object itself, the people who can reach it, the API tokens that automate
it, the alerts that page someone when it breaks, log delivery, DNS defaults, a secrets store and cross account
resource sharing.

**This is the once per account bootstrap, not a per workload module.** That is the opinion it encodes. An
account is a singleton, so the root module deliberately covers only the three things that are true exactly
once for an account and that every other module then depends on: the account, its members and groups, and the
baseline notification policies. Run it first, run it once, and let the zone, network, security and workers
modules consume the account ID it emits. Everything past that first apply is optional surface, published as
seven separate submodules that you call as you need them rather than carrying as dead configuration.

`create_account` defaults to false on purpose. Creating a `cloudflare_account` through the API requires a
tenant or reseller relationship with Cloudflare, so almost every caller passes an existing `account_id`
instead. The same singleton logic applies inside the submodules: `dns-settings` has `create_dns_settings`
defaulting to false because there is exactly one `cloudflare_account_dns_settings` per account, and two
Terraform configurations fighting over it is a slow, confusing outage.

Three inputs carry real secrets and are marked `sensitive`, but sensitive means "not printed", not "not
stored". API token values (disclosed by Cloudflare exactly once, at creation), Logpush `destination_conf`
(which embeds the S3, GCS or Azure access key in the URL) and secrets store `value` all land in Terraform
state in the clear. Treat the state backend as a secret store, encrypt it, and restrict who can read it.

| Concern | Where it lives | Note |
|---------|----------------|------|
| Account, members, groups, baseline alerts | root module | Run once, before everything else. |
| Machine credentials | `modules/api-token` | Permission group IDs and resource scopes are opaque IDs, not schema values. |
| Log delivery | `modules/logpush` | Destination ownership must be proven with a challenge before a job will run. |
| Account wide DNS defaults | `modules/dns-settings` | Singleton resource. Only one configuration may own it. |
| Secret material for Workers and Access | `modules/secrets-store` | Cloudflare never reads values back, so Terraform cannot detect drift. |
| Cross account resource sharing | `modules/sharing` | Recipients and resources can be inline on the share or attached later. |

Targets Cloudflare provider v5. Cloudflare regenerated the provider from its OpenAPI spec in v5.0.0 and
renamed most resources, so check resource names and attributes against the current provider documentation
rather than against provider v4 examples.


## Prerequisites and Providers

This table contains both Prerequisites and Providers:

| Description | Name | Version |
|-------------|------|---------|
| Prerequisite | Terraform | >= 1.12.0 |
| Prerequisite | OpenTofu | >= 1.12.0 |
| Provider | cloudflare | ~> 5.24 |

---


## 🧩 Submodules

Each submodule is separately addressable with the double slash source syntax, so you can take only the piece you need instead of the whole root module.

| Submodule | Source | Description |
|-----------|--------|-------------|
| `member` | `terraform-cf-modules/account/cloudflare//modules/member` | `cloudflare_account_member`, `cloudflare_user_group` and `cloudflare_user_group_members`. Members take either legacy `roles` or scoped `policies`, never both. Group membership can reference members by key, so no IDs need to be plumbed by hand. |
| `api-token` | `terraform-cf-modules/account/cloudflare//modules/api-token` | `cloudflare_api_token` (user scoped) and `cloudflare_account_token` (account scoped). Policies are a keyed map so adding one does not shift the others in state. Supports IP allow lists and expiry, and returns the token value as a sensitive output. |
| `notification` | `terraform-cf-modules/account/cloudflare//modules/notification` | `cloudflare_notification_policy` and `cloudflare_notification_policy_webhooks`. Delivers to email, PagerDuty or webhook, and webhooks are referenced by key from the policies that use them. |
| `logpush` | `terraform-cf-modules/account/cloudflare//modules/logpush` | `cloudflare_logpush_job`, `cloudflare_logpush_ownership_challenge` and `cloudflare_logpull_retention`. Jobs are account scoped or zone scoped, never both, and challenges are referenced by key so the ordering is expressed for you. |
| `secrets-store` | `terraform-cf-modules/account/cloudflare//modules/secrets-store` | `cloudflare_secrets_store` and `cloudflare_secrets_store_secret`. Scopes must be listed alphabetically because Cloudflare rejects any other order. |
| `dns-settings` | `terraform-cf-modules/account/cloudflare//modules/dns-settings` | `cloudflare_account_dns_settings` and `cloudflare_dns_firewall`. Account wide zone defaults plus DNS Firewall clusters with caching, rate limiting and attack mitigation. |
| `sharing` | `terraform-cf-modules/account/cloudflare//modules/sharing` | `cloudflare_share`, `cloudflare_share_recipient` and `cloudflare_share_resource`. Shares rulesets, gateway policies and similar resources with another account or organization. |

---


## 🚀 Usage

### Root module

The once per account bootstrap: point at an existing account, invite the people who administer it, and set up
the baseline alert that tells them when origins start failing.

```hcl
module "account" {
  source  = "terraform-cf-modules/account/cloudflare"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  account_settings = {
    abuse_contact_email = "security@example.com"
    enforce_twofactor   = true
  }

  members = {
    platform_lead = {
      email = "platform@example.com"
      roles = [var.administrator_role_id]
    }

    auditor = {
      email = "audit@example.com"
      policies = [{
        access               = "allow"
        permission_group_ids = [var.analytics_read_permission_group_id]
        resource_group_ids   = [var.account_resource_group_id]
      }]
    }
  }

  groups = {
    network_engineers = {
      name = "Network engineers"
      policies = [{
        access               = "allow"
        permission_group_ids = [var.dns_write_permission_group_id]
        resource_group_ids   = [var.account_resource_group_id]
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
      description  = "Fires when the origin 5xx rate crosses the configured threshold."
      emails       = ["platform@example.com"]
      webhook_keys = ["ops_channel"]
    }
  }
}
```

### API tokens as a submodule

A token's reach is the product of two opaque ID sets that are not discoverable from the provider schema:
`permission_group_ids` (what the token may do, from
`GET /accounts/{account_id}/tokens/permission_groups`) and `resources` (where it may do it). The token value
is returned once by Cloudflare and is available on the sensitive `account_token_values` output.

```hcl
module "api_token" {
  source  = "terraform-cf-modules/account/cloudflare//modules/api-token"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  account_tokens = {
    ci = {
      name       = "ci-dns"
      status     = "active"
      expires_on = "2027-01-01T00:00:00Z"

      # Only accept this token from the CI egress range.
      request_ip_in = ["203.0.113.0/24"]

      policies = {
        dns_edit = {
          effect               = "allow"
          permission_group_ids = [var.dns_write_permission_group_id]
          resources = {
            "com.cloudflare.api.account.zone.${var.zone_id}" = "*"
          }
        }

        analytics_read = {
          effect               = "allow"
          permission_group_ids = [var.analytics_read_permission_group_id]
          resources = {
            "com.cloudflare.api.account.${var.account_id}" = "*"
          }
        }
      }
    }
  }
}
```

### Logpush with an ownership challenge

Cloudflare writes a challenge file into the destination and the token inside it has to come back as the job's
ownership challenge. Create the challenge in the same block and reference it by key, and Terraform derives the
ordering. `destination_conf` embeds the sink credential, so both inputs are sensitive.

```hcl
module "logpush" {
  source  = "terraform-cf-modules/account/cloudflare//modules/logpush"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

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
    }
  }
}
```

### Many accounts from one block

```hcl
module "accounts" {
  source  = "terraform-cf-modules/account/cloudflare//wrappers"
  version = "~> 0.1"

  defaults = {
    account_settings = {
      abuse_contact_email = "security@example.com"
      enforce_twofactor   = true
    }

    notification_policies = {
      origin_errors = {
        name       = "Origin error rate"
        alert_type = "http_alert_origin_error"
        emails     = ["platform@example.com"]
      }
    }
  }

  items = {
    production = { account_id = var.production_account_id }
    staging    = { account_id = var.staging_account_id }
  }
}
```

---


## 📦 Examples

> ⚠️ **Important:** Avoid using the `main` branch directly, as it may include unstable changes. Always use stable [release versions](https://github.com/terraform-cf-modules/terraform-cloudflare-account/releases).

Explore real-world usage scenarios and implementation patterns in the [`examples/`](./examples/) directory.

---


## 📥 Inputs and Outputs

Detailed input variables and output values are documented for easier integration and day-to-day usage.

📘 [View full documentation](docs/io.md)

---


## 📝 Changelog

Track module updates, improvements, and breaking changes across versions.

📌 [View Changelog](CHANGELOG.md)

---


## ✨ Contributors

Big thanks to our contributors for elevating our project with their dedication and expertise!

<div align="center">
  <a href="https://github.com/terraform-cf-modules/terraform-cloudflare-account/graphs/contributors" title="Contributors">
    <img src="https://contrib.rocks/image?repo=terraform-cf-modules/terraform-cloudflare-account" />
  </a>
</div>

All contributors must follow the [Conventional Commits](https://www.conventionalcommits.org) specification for commit messages.

---


## 🚀 Our Accomplishment

We maintain Terraform modules across AWS, Azure, Google Cloud, DigitalOcean, Hetzner Cloud and Cloudflare 🙌.

- [**Terraform Module Registry**](https://registry.terraform.io/namespaces/terraform-cf-modules): Discover our Cloudflare modules here.
- [**Full module catalog**](https://github.com/clouddrove/toc): Every CloudDrove module and submodule, across every cloud.

---

## Notes

- Do not use the `main` branch for production deployments.
- Always reference a stable version using Git tags or official releases.
- Using tagged versions ensures consistency, stability, and reproducible deployments.

---

## Feedback

Report issues or request features on [GitHub](https://github.com/terraform-cf-modules/terraform-cloudflare-account/issues), or write to [business@clouddrove.com](mailto:business@clouddrove.com).

## About us

At [CloudDrove](https://clouddrove.com), we build reliable, secure and cost efficient cloud native solutions. Join our [Slack community](https://www.launchpass.com/devops-talks).
