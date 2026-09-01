# Wrapper

Creates many instances of the root module from a single map, so a fleet of accounts does not need a repeated
`module` block per account.

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
    sandbox    = { account_id = var.sandbox_account_id, enabled = false }
  }
}
```

Values in `defaults` apply to every item unless the item overrides them, which makes it the natural place for a
baseline alert policy that every account should carry.

Keys in `items` become the state addresses, so keep them stable. Renaming a key destroys and recreates that
instance.

The `wrapper` output is marked sensitive because the root module's outputs include webhook secrets. Use the
`account_ids` output, or index into a specific instance, when you need a plain value.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_wrapper"></a> [wrapper](#module\_wrapper) | ../ | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Values applied to every item unless the item overrides them. | `any` | `{}` | no |
| <a name="input_items"></a> [items](#input\_items) | Map of module instances to create, keyed by a stable identifier. | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_ids"></a> [account\_ids](#output\_account\_ids) | Map of the account ID each instance is anchored on, keyed as in var.items. |
| <a name="output_wrapper"></a> [wrapper](#output\_wrapper) | Map of module outputs, keyed by the same keys as var.items. |
<!-- END_TF_DOCS -->
