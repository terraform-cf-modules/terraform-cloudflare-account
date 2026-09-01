<p align="center">
  <img width="1000" alt="CloudDrove Banner" src="https://clouddrove.s3.ca-central-1.amazonaws.com/img/clouddrove-github-cover.png" />
</p>

<h1 align="center">Terraform Cloudflare Account</h1>
<p align="center"><em>Account bootstrap, members and groups, API tokens, notifications, Logpush, and secrets store.</em></p>

<p align="center">
  <a href="https://www.terraform.io"><img src="https://img.shields.io/badge/terraform-%3E%3D%201.10-844FBA?logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="https://opentofu.org"><img src="https://img.shields.io/badge/opentofu-%3E%3D%201.9-FFDA18?logo=opentofu&logoColor=black" alt="OpenTofu" /></a>
  <a href="https://registry.terraform.io/providers/cloudflare/cloudflare/latest"><img src="https://img.shields.io/badge/provider-cloudflare%20~%3E%205.24-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Provider" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License" /></a>
</p>

---

## What this module is

The root module is what a platform team runs **once per Cloudflare account**: the account object, the people who
can reach it, and the baseline alerts that tell them when something is wrong.

Everything else in the account surface is a building block under `modules/`, composed as needed. They are
deliberately not called from the root, because tokens, log export, secrets, DNS defaults and sharing are
decisions a team makes separately, often in a different state file with a different blast radius.

| Submodule | Resources |
|-----------|-----------|
| [`member`](modules/member) | `cloudflare_account_member`, `cloudflare_user_group`, `cloudflare_user_group_members` |
| [`api-token`](modules/api-token) | `cloudflare_api_token`, `cloudflare_account_token` |
| [`notification`](modules/notification) | `cloudflare_notification_policy`, `cloudflare_notification_policy_webhooks` |
| [`logpush`](modules/logpush) | `cloudflare_logpush_job`, `cloudflare_logpush_ownership_challenge`, `cloudflare_logpull_retention` |
| [`secrets-store`](modules/secrets-store) | `cloudflare_secrets_store`, `cloudflare_secrets_store_secret` |
| [`dns-settings`](modules/dns-settings) | `cloudflare_account_dns_settings`, `cloudflare_dns_firewall` |
| [`sharing`](modules/sharing) | `cloudflare_share`, `cloudflare_share_recipient`, `cloudflare_share_resource` |

`cloudflare_account` itself lives in the root module. See [docs/architecture.md](docs/architecture.md) for the
full resource map, the dependency order, and the provider quirks worth knowing.

---

## Usage

### Root module

```hcl
module "account" {
  source  = "terraform-cf-modules/account/cloudflare"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  members = {
    platform_lead = {
      email = "platform@example.com"
      roles = [var.administrator_role_id]
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
      emails       = ["platform@example.com"]
      webhook_keys = ["ops_channel"]
    }
  }
}
```

### Submodule

```hcl
module "api_token" {
  source  = "terraform-cf-modules/account/cloudflare//modules/api-token"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  account_tokens = {
    ci = {
      name = "ci-dns"

      policies = {
        dns_edit = {
          effect               = "allow"
          permission_group_ids = [var.dns_write_permission_group_id]

          resources = {
            "com.cloudflare.api.account.zone.${var.zone_id}" = "*"
          }
        }
      }
    }
  }
}
```

### Wrapper for many accounts

```hcl
module "accounts" {
  source = "terraform-cf-modules/account/cloudflare//wrappers"

  defaults = {
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

## Examples

| Example | What it shows |
|---------|---------------|
| [`examples/basic`](examples/basic) | Minimum viable configuration: one member, one alert. |
| [`examples/complete`](examples/complete) | Every optional feature of the root module and all seven submodules. |
| [`examples/api-token`](examples/api-token) | Permission groups, resource scopes, IP conditions, and where the token value goes. |
| [`examples/logpush`](examples/logpush) | Ownership challenges, account versus zone scope, and credential handling in `destination_conf`. |

Examples default to placeholder IDs (32 hex zeroes) so they plan without credentials.

---

## Secrets

This module never accepts the provider's own API token as an input. Authentication belongs to the caller.

It does **create and store** secret material, which is a different thing. Four inputs carry secrets and are
marked `sensitive`:

| Input | Submodule | Carries |
|-------|-----------|---------|
| `notification_webhooks` / `webhooks` | root, `notification` | the `cf-webhook-auth` secret |
| `jobs`, `ownership_challenges` | `logpush` | `destination_conf`, which embeds the sink's access key |
| `secrets` | `secrets-store` | the secret material itself |

And these outputs are `sensitive = true`:

`user_tokens`, `account_tokens`, `user_token_values`, `account_token_values`, `notification_webhooks`,
`logpush jobs`, `ownership_challenges`, `ownership_challenge_filenames`, `secrets`.

The corresponding `*_ids` outputs are not sensitive, because an ID is not a secret.

**All of it lands in Terraform state.** API token values in particular are disclosed by Cloudflare exactly once,
at creation, so they exist in state or nowhere. Keep state in an encrypted backend with restricted access.

---

## Repository layout

```
terraform.tf          provider and version requirements
main.tf               root module resources
variables.tf          root module inputs
outputs.tf            root module outputs
locals.tf             locals
modules/<name>/       composable building blocks, same file layout
examples/basic/       minimum viable example
examples/complete/    every optional feature turned on
examples/api-token/   API token scoping, explained
examples/logpush/     Logpush ownership and credentials, explained
wrappers/             for_each wrapper for many instances
tests/                native terraform test files
docs/                 architecture notes
```

---

## The rules

Full detail lives in the [organisation contributing guide](https://github.com/terraform-cf-modules/.github/blob/main/CONTRIBUTING.md).
The short version:

- **Product scoped, not resource scoped.** One module maps to a Cloudflare product area.
- **Provider v5 only.** Verify every resource and attribute against the
  [current provider docs](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs).
- **`enabled` everywhere**, honoured on every resource.
- **Maps of objects, never lists.** A list reorder destroys and recreates resources.
- **`validation` blocks on every enum.**
- **No `provider` block inside a module.** Authentication belongs to the caller.
- **No credentials as inputs.** Secret outputs are marked `sensitive`.
- **No tagging or labelling convention.** Cloudflare has no general tag surface.

---

## Local development

```bash
pre-commit install

make fmt        # terraform fmt -recursive
make validate   # init and validate every directory
make lint       # tflint
make docs       # regenerate the terraform-docs blocks
make test       # mocked terraform test, no credentials needed
make security   # trivy, checkov, gitleaks
make ci         # all of the above
```

`make test` runs against `mock_provider`, so it needs no Cloudflare credentials. The live tests in
`tests/integration.tftest.hcl` run only on schedule and manual dispatch, and deliberately never create an
account: account creation needs a tenant relationship and the object cannot be cleanly destroyed afterwards.

---

## CI

Most workflows call the shared, actively maintained
[clouddrove/github-shared-workflows](https://github.com/clouddrove/github-shared-workflows) at `@v2`, so the
standard changes in one place for every repository.

| Workflow | Source | Purpose |
|----------|--------|---------|
| `tf-checks` | shared | init and validate both examples |
| `tflint` | shared | lint |
| `checkov` | shared | policy scan |
| `gitleaks` | shared | secret scan |
| `pr_checks` | shared | Conventional Commit pull request title |
| `auto_assignee` | shared | reviewer assignment |
| `automerge` | shared | auto merge on green |
| `stale_pr` | shared | stale handling |
| `readme` | shared | rebuild README from README.yaml |
| `tag-release` | shared | tag and changelog on merge |
| `opentofu` | local | OpenTofu compatibility, no shared equivalent yet |
| `test` | local | `terraform test` with mocked provider |
| `integration` | local | live apply against a test account, scheduled only |

### Required organisation secrets

| Secret | Used by |
|--------|---------|
| `GITHUB` | `tflint`, `tag-release`, `auto_assignee`, `automerge`, `readme` |
| `SLACK_WEBHOOK_TERRAFORM` | `readme` |
| `CLOUDFLARE_API_TOKEN` | `integration` |
| `CLOUDFLARE_TEST_ACCOUNT_ID` | `integration` |
| `CLOUDFLARE_TEST_ZONE_ID` | `integration` |

---

## Inputs and outputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_member"></a> [member](#module\_member) | ./modules/member | n/a |
| <a name="module_notification"></a> [notification](#module\_notification) | ./modules/notification | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_account.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the resources. Required for account scoped resources, and ignored when var.create\_account is true. | `string` | `null` | no |
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | Name of the account to create. Required when var.create\_account is true. | `string` | `null` | no |
| <a name="input_account_settings"></a> [account\_settings](#input\_account\_settings) | Account settings. `enforce_twofactor` requires every member to have Two-Factor Authentication enabled. | <pre>object({<br/>    abuse_contact_email = optional(string)<br/>    enforce_twofactor   = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_account_unit_id"></a> [account\_unit\_id](#input\_account\_unit\_id) | Tenant unit ID to create the account under. Only meaningful for tenant and reseller relationships. | `string` | `null` | no |
| <a name="input_create_account"></a> [create\_account](#input\_create\_account) | Whether to create the Cloudflare account (`cloudflare_account`). Creating accounts through the API requires a<br/>tenant or reseller relationship, so most callers leave this false and pass an existing `var.account_id`. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this module. Set to false to disable the module without removing the block. | `bool` | `true` | no |
| <a name="input_group_members"></a> [group\_members](#input\_group\_members) | Membership of user groups, keyed by a stable identifier. Reference a group by `group_key` (a key of<br/>`var.groups`) or by `user_group_id`, and members by `member_keys` (keys of `var.members`) or `member_ids`. | <pre>map(object({<br/>    group_key     = optional(string)<br/>    user_group_id = optional(string)<br/>    member_keys   = optional(list(string), [])<br/>    member_ids    = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_groups"></a> [groups](#input\_groups) | User groups to create, keyed by a stable identifier. | <pre>map(object({<br/>    name = string<br/>    policies = optional(list(object({<br/>      access               = string<br/>      permission_group_ids = list(string)<br/>      resource_group_ids   = list(string)<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_members"></a> [members](#input\_members) | Account members to invite, keyed by a stable identifier. Supply either `roles` (a set of Cloudflare role IDs)<br/>or `policies`, not both. | <pre>map(object({<br/>    email  = string<br/>    roles  = optional(set(string))<br/>    status = optional(string)<br/>    policies = optional(list(object({<br/>      access               = string<br/>      permission_group_ids = list(string)<br/>      resource_group_ids   = list(string)<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_notification_policies"></a> [notification\_policies](#input\_notification\_policies) | Baseline notification policies, keyed by a stable identifier. Every policy needs at least one delivery<br/>mechanism. `webhook_keys` reference keys of `var.notification_webhooks`. | <pre>map(object({<br/>    name           = string<br/>    alert_type     = string<br/>    description    = optional(string)<br/>    enabled        = optional(bool, true)<br/>    alert_interval = optional(string)<br/>    emails         = optional(list(string), [])<br/>    pagerduty_ids  = optional(list(string), [])<br/>    webhook_keys   = optional(list(string), [])<br/>    webhook_ids    = optional(list(string), [])<br/>    filters = optional(object({<br/>      actions                         = optional(list(string))<br/>      affected_asns                   = optional(list(string))<br/>      affected_components             = optional(list(string))<br/>      affected_locations              = optional(list(string))<br/>      airport_code                    = optional(list(string))<br/>      alert_trigger_preferences       = optional(list(string))<br/>      alert_trigger_preferences_value = optional(list(string))<br/>      enabled                         = optional(list(string))<br/>      environment                     = optional(list(string))<br/>      event                           = optional(list(string))<br/>      event_source                    = optional(list(string))<br/>      event_type                      = optional(list(string))<br/>      group_by                        = optional(list(string))<br/>      health_check_id                 = optional(list(string))<br/>      incident_impact                 = optional(list(string))<br/>      input_id                        = optional(list(string))<br/>      insight_class                   = optional(list(string))<br/>      limit                           = optional(list(string))<br/>      logo_tag                        = optional(list(string))<br/>      megabits_per_second             = optional(list(string))<br/>      new_health                      = optional(list(string))<br/>      new_status                      = optional(list(string))<br/>      packets_per_second              = optional(list(string))<br/>      pool_id                         = optional(list(string))<br/>      pop_names                       = optional(list(string))<br/>      product                         = optional(list(string))<br/>      project_id                      = optional(list(string))<br/>      protocol                        = optional(list(string))<br/>      query_tag                       = optional(list(string))<br/>      requests_per_second             = optional(list(string))<br/>      selectors                       = optional(list(string))<br/>      services                        = optional(list(string))<br/>      slo                             = optional(list(string))<br/>      status                          = optional(list(string))<br/>      target_hostname                 = optional(list(string))<br/>      target_ip                       = optional(list(string))<br/>      target_zone_name                = optional(list(string))<br/>      traffic_exclusions              = optional(list(string))<br/>      tunnel_id                       = optional(list(string))<br/>      tunnel_name                     = optional(list(string))<br/>      type                            = optional(list(string))<br/>      where                           = optional(list(string))<br/>      zones                           = optional(list(string))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_notification_webhooks"></a> [notification\_webhooks](#input\_notification\_webhooks) | Webhook destinations for notification policies, keyed by a stable identifier. Sensitive because it carries the cf-webhook-auth secret. | <pre>map(object({<br/>    name   = string<br/>    url    = string<br/>    secret = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account"></a> [account](#output\_account) | The cloudflare\_account resource, or null when the account was not created by this module. |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | Account ID everything in this module is anchored on. The created account when var.create\_account is true, otherwise var.account\_id. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this module created its resources. |
| <a name="output_group_ids"></a> [group\_ids](#output\_group\_ids) | Map of user group IDs, keyed as in var.groups. |
| <a name="output_group_member_ids"></a> [group\_member\_ids](#output\_group\_member\_ids) | Map of user group membership IDs, keyed as in var.group\_members. |
| <a name="output_group_members"></a> [group\_members](#output\_group\_members) | Map of created cloudflare\_user\_group\_members resources, keyed as in var.group\_members. |
| <a name="output_groups"></a> [groups](#output\_groups) | Map of created cloudflare\_user\_group resources, keyed as in var.groups. |
| <a name="output_member_ids"></a> [member\_ids](#output\_member\_ids) | Map of account member IDs, keyed as in var.members. |
| <a name="output_members"></a> [members](#output\_members) | Map of created cloudflare\_account\_member resources, keyed as in var.members. |
| <a name="output_notification_policies"></a> [notification\_policies](#output\_notification\_policies) | Map of created cloudflare\_notification\_policy resources, keyed as in var.notification\_policies. |
| <a name="output_notification_policy_ids"></a> [notification\_policy\_ids](#output\_notification\_policy\_ids) | Map of notification policy IDs, keyed as in var.notification\_policies. |
| <a name="output_notification_webhook_ids"></a> [notification\_webhook\_ids](#output\_notification\_webhook\_ids) | Map of webhook destination IDs, keyed as in var.notification\_webhooks. |
| <a name="output_notification_webhooks"></a> [notification\_webhooks](#output\_notification\_webhooks) | Map of created webhook destinations, keyed as in var.notification\_webhooks. Sensitive because it carries the webhook secret. |
<!-- END_TF_DOCS -->

---

## License

Apache 2.0. See [LICENSE](LICENSE).

Maintained by [CloudDrove](https://clouddrove.com) and [Cloud Wizz](https://github.com/cloud-wizz).
