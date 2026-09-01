# Submodule: sharing

Cross account resource sharing.

| Resource | Purpose |
|----------|---------|
| `cloudflare_share` | A share owned by this account, created with its initial recipients and resources. |
| `cloudflare_share_recipient` | An account or organisation added to a share after creation. |
| `cloudflare_share_resource` | An object added to a share after creation. |

```hcl
module "sharing" {
  source  = "terraform-cf-modules/account/cloudflare//modules/sharing"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  shares = {
    gateway_baseline = {
      name = "gateway-baseline"

      recipients = [{
        recipient_account_id = var.recipient_account_id
      }]

      resources = [{
        resource_id         = var.gateway_policy_id
        resource_type       = "gateway-policy"
        resource_account_id = var.account_id
        meta                = jsonencode({ description = "Shared block list" })
      }]
    }
  }

  resources = {
    extra_ruleset = {
      share_key           = "gateway_baseline"
      resource_id         = var.custom_ruleset_id
      resource_type       = "custom-ruleset"
      resource_account_id = var.account_id
    }
  }
}
```

## Notes

- **A share is created with its recipients and resources inline.** `cloudflare_share_recipient` and
  `cloudflare_share_resource` exist for anything added afterwards. Do not declare the same recipient or resource
  both inline and standalone; Cloudflare will report a conflict.
- A recipient is either an account (`recipient_account_id`) or an organisation (`organization_id`), never both.
- `resource_type` is a closed set: `custom-ruleset`, `gateway-policy`, `gateway-destination-ip`,
  `gateway-block-page-settings`, `gateway-extended-email-matching`, `idp-federation-grant`.
- `meta` is a JSON encoded string, not an object. Use `jsonencode({ ... })`. It defaults to `"{}"`.
- The recipient must accept the share on their side before it becomes active. `association_status` on the
  recipient resource reports where it is in that handshake, so a fresh apply normally shows `associating`.

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
| [cloudflare_share.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/share) | resource |
| [cloudflare_share_recipient.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/share_recipient) | resource |
| [cloudflare_share_resource.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/share_resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the shares. This is the sending side of the share. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_recipients"></a> [recipients](#input\_recipients) | Extra recipients added to an existing share (`cloudflare_share_recipient`), keyed by a stable identifier.<br/><br/>Reference the share either by `share_key` (a key of `var.shares`) or by `share_id`. | <pre>map(object({<br/>    share_key            = optional(string)<br/>    share_id             = optional(string)<br/>    recipient_account_id = optional(string)<br/>    organization_id      = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Extra resources added to an existing share (`cloudflare_share_resource`), keyed by a stable identifier.<br/><br/>Reference the share either by `share_key` (a key of `var.shares`) or by `share_id`. | <pre>map(object({<br/>    share_key           = optional(string)<br/>    share_id            = optional(string)<br/>    resource_id         = string<br/>    resource_type       = string<br/>    resource_account_id = string<br/>    meta                = optional(string, "{}")<br/>  }))</pre> | `{}` | no |
| <a name="input_shares"></a> [shares](#input\_shares) | Shares (`cloudflare_share`), keyed by a stable identifier.<br/><br/>A share is created with its initial recipients and resources inline. Recipients and resources added later<br/>are separate resources: see `var.recipients` and `var.resources`.<br/><br/>Each recipient sets exactly one of `recipient_account_id` or `organization_id`. | <pre>map(object({<br/>    name = string<br/>    recipients = list(object({<br/>      recipient_account_id = optional(string)<br/>      organization_id      = optional(string)<br/>    }))<br/>    resources = list(object({<br/>      resource_id         = string<br/>      resource_type       = string<br/>      resource_account_id = string<br/>      meta                = optional(string, "{}")<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_recipient_ids"></a> [recipient\_ids](#output\_recipient\_ids) | Map of share recipient IDs, keyed as in var.recipients. |
| <a name="output_recipients"></a> [recipients](#output\_recipients) | Map of created cloudflare\_share\_recipient resources, keyed as in var.recipients. |
| <a name="output_resource_ids"></a> [resource\_ids](#output\_resource\_ids) | Map of shared resource IDs, keyed as in var.resources. |
| <a name="output_resources"></a> [resources](#output\_resources) | Map of created cloudflare\_share\_resource resources, keyed as in var.resources. |
| <a name="output_share_ids"></a> [share\_ids](#output\_share\_ids) | Map of share IDs, keyed as in var.shares. |
| <a name="output_shares"></a> [shares](#output\_shares) | Map of created cloudflare\_share resources, keyed as in var.shares. |
<!-- END_TF_DOCS -->
