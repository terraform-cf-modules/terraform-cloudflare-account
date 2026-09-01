# Submodule: api-token

Cloudflare API tokens, both user scoped and account scoped.

| Resource | Purpose |
|----------|---------|
| `cloudflare_api_token` | User scoped token. Its reach is bounded by the creating user's own access. |
| `cloudflare_account_token` | Account scoped token, bound to one account. |

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

      # Only accept the token from the CI egress range.
      request_ip_in = ["203.0.113.0/24"]

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

## The token value is a secret

Both resources expose a `value` attribute. The schema marks it `SENSITIVE`, Cloudflare discloses it exactly once
at creation, and there is no way to read it back. Every output here that carries it is `sensitive = true`:

| Output | Sensitive |
|--------|-----------|
| `user_tokens`, `account_tokens` | yes, the full object carries `value` |
| `user_token_values`, `account_token_values` | yes |
| `user_token_ids`, `account_token_ids` | no |

The value is written to Terraform state. Treat state as a secret and keep it in an encrypted backend.

This module **creates** tokens. It never **accepts** one as an input: the provider's own authentication belongs
to the caller.

## Policies

`policies` is a map keyed by a stable identifier, not a list, so adding or removing a policy does not shift the
others. The module sorts by key before handing the list to the provider, which keeps plans stable.

Each policy needs:

- `effect` — `allow` or `deny`. Defaults to `allow`.
- `permission_group_ids` — what the token may do. List them with
  `GET /accounts/{account_id}/tokens/permission_groups`. These IDs are not in the provider schema.
- `resources` **or** `resources_json` — where it may do it. `resources` is a map of scope string to value and is
  encoded to JSON for you. `resources_json` is a raw JSON string for nested scopes the map form cannot express.

Common scope strings:

| Scope | Meaning |
|-------|---------|
| `com.cloudflare.api.account.<account_id>` | the whole account |
| `com.cloudflare.api.account.zone.<zone_id>` | one zone |
| `com.cloudflare.api.account.zone.*` | every zone in the enclosing account scope |

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

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_account_token.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/account_token) | resource |
| [cloudflare_api_token.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/api_token) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the account scoped tokens. Required when var.account\_tokens is not empty. | `string` | `null` | no |
| <a name="input_account_tokens"></a> [account\_tokens](#input\_account\_tokens) | Account scoped API tokens (`cloudflare_account_token`), keyed by a stable identifier. Same shape as<br/>`var.user_tokens`. The generated token value is available on the `account_token_values` output and is marked<br/>sensitive. | <pre>map(object({<br/>    name              = string<br/>    status            = optional(string)<br/>    expires_on        = optional(string)<br/>    not_before        = optional(string)<br/>    request_ip_in     = optional(list(string))<br/>    request_ip_not_in = optional(list(string))<br/>    policies = map(object({<br/>      effect               = optional(string, "allow")<br/>      permission_group_ids = list(string)<br/>      resources            = optional(map(string))<br/>      resources_json       = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_user_tokens"></a> [user\_tokens](#input\_user\_tokens) | User scoped API tokens (`cloudflare_api_token`), keyed by a stable identifier.<br/><br/>`policies` is a map keyed by a stable identifier so that adding or removing a policy does not shift the<br/>others. Each policy needs `permission_group_ids` and one of `resources` (a map of resource scope to value,<br/>encoded to JSON for you) or `resources_json` (a raw JSON string for scopes the map form cannot express).<br/><br/>The generated token value is available on the `user_token_values` output and is marked sensitive. | <pre>map(object({<br/>    name              = string<br/>    status            = optional(string)<br/>    expires_on        = optional(string)<br/>    not_before        = optional(string)<br/>    request_ip_in     = optional(list(string))<br/>    request_ip_not_in = optional(list(string))<br/>    policies = map(object({<br/>      effect               = optional(string, "allow")<br/>      permission_group_ids = list(string)<br/>      resources            = optional(map(string))<br/>      resources_json       = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_token_ids"></a> [account\_token\_ids](#output\_account\_token\_ids) | Map of account API token IDs, keyed as in var.account\_tokens. |
| <a name="output_account_token_values"></a> [account\_token\_values](#output\_account\_token\_values) | Map of account API token secret values, keyed as in var.account\_tokens. Disclosed by the API only on creation. |
| <a name="output_account_tokens"></a> [account\_tokens](#output\_account\_tokens) | Map of created cloudflare\_account\_token resources, keyed as in var.account\_tokens. Contains the token value. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_user_token_ids"></a> [user\_token\_ids](#output\_user\_token\_ids) | Map of user API token IDs, keyed as in var.user\_tokens. |
| <a name="output_user_token_values"></a> [user\_token\_values](#output\_user\_token\_values) | Map of user API token secret values, keyed as in var.user\_tokens. Disclosed by the API only on creation. |
| <a name="output_user_tokens"></a> [user\_tokens](#output\_user\_tokens) | Map of created cloudflare\_api\_token resources, keyed as in var.user\_tokens. Contains the token value. |
<!-- END_TF_DOCS -->
