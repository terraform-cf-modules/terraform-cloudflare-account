# Submodule: secrets-store

Account level secrets stores and the secrets inside them.

| Resource | Purpose |
|----------|---------|
| `cloudflare_secrets_store` | A named store scoped to one account. |
| `cloudflare_secrets_store_secret` | One secret inside a store. |

```hcl
module "secrets_store" {
  source  = "terraform-cf-modules/account/cloudflare//modules/secrets-store"
  version = "~> 0.1"

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
```

## Notes

- **`var.secrets` is sensitive.** `value` is the secret material itself. Cloudflare treats it as write only and
  never returns it, so Terraform cannot detect drift on it, but it does live in Terraform state. Source it from a
  data source or a `TF_VAR_` environment variable rather than committing it. Terraform refuses a sensitive value
  as `for_each`, so the module drives `for_each` from a view with `value` blanked out and reads the real value
  at the point of use.
- **`scopes` must be alphabetical.** Cloudflare rejects any other order. Valid values are `access`,
  `ai_gateway`, `dex` and `workers`. The module validates both the values and the ordering.
- A secret is limited to 64 KiB.
- Reference the store by `store_key` (a key of `var.stores`) or by `store_id` for a store this module does not
  manage.
- This module **stores** secrets in Cloudflare. That is different from accepting the provider's own credential
  as an input, which no module here does.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the secrets stores. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Secrets (`cloudflare_secrets_store_secret`), keyed by a stable identifier.<br/><br/>**This variable is sensitive.** `value` is the secret material itself. Cloudflare never reads it back, so<br/>Terraform cannot detect drift on it, but it does live in Terraform state. Source it from a data source or a<br/>`TF_VAR_` environment variable rather than committing it.<br/><br/>Reference the store either by `store_key` (a key of `var.stores`) or by `store_id` for a store this module<br/>does not manage. `scopes` must be listed in alphabetical order; Cloudflare rejects any other order. | <pre>map(object({<br/>    name      = string<br/>    value     = string<br/>    scopes    = list(string)<br/>    comment   = optional(string)<br/>    store_key = optional(string)<br/>    store_id  = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_stores"></a> [stores](#input\_stores) | Secrets stores (`cloudflare_secrets_store`), keyed by a stable identifier. | <pre>map(object({<br/>    name = string<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Map of secret IDs, keyed as in var.secrets. |
| <a name="output_secrets"></a> [secrets](#output\_secrets) | Map of created cloudflare\_secrets\_store\_secret resources, keyed as in var.secrets. Sensitive because it carries the secret value. |
| <a name="output_store_ids"></a> [store\_ids](#output\_store\_ids) | Map of secrets store IDs, keyed as in var.stores. |
| <a name="output_stores"></a> [stores](#output\_stores) | Map of created cloudflare\_secrets\_store resources, keyed as in var.stores. |
<!-- END_TF_DOCS -->
