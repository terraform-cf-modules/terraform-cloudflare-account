# Submodule: notification

Alert policies and the webhook destinations they deliver to.

| Resource | Purpose |
|----------|---------|
| `cloudflare_notification_policy_webhooks` | A webhook delivery destination. |
| `cloudflare_notification_policy` | An alert rule and where it is delivered. |

```hcl
module "notification" {
  source  = "terraform-cf-modules/account/cloudflare//modules/notification"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  webhooks = {
    ops_channel = {
      name   = "Ops channel"
      url    = "https://hooks.example.com/cloudflare"
      secret = var.webhook_secret
    }
  }

  policies = {
    origin_errors = {
      name         = "Origin error rate"
      alert_type   = "http_alert_origin_error"
      emails       = ["platform@example.com"]
      webhook_keys = ["ops_channel"]

      filters = {
        zones = [var.zone_id]
      }
    }
  }
}
```

## Notes

- **`var.webhooks` is sensitive.** It carries `secret`, which Cloudflare sends in the `cf-webhook-auth` header.
  Cloudflare never returns it, so Terraform cannot detect drift on it. A sensitive value cannot drive `for_each`,
  so the resource iterates over the unmarked keys and looks each entry up by key.
- **Every policy needs a mechanism.** Set at least one of `emails`, `pagerduty_ids`, `webhook_keys` (keys of
  `var.webhooks`) or `webhook_ids` (destinations this module does not manage). The module validates this.
- **`filters` fields depend on `alert_type`.** The provider accepts the same 43 field object for every alert
  type, but each alert type reads only a few of them. Setting an irrelevant field is silently ignored. Check the
  [Cloudflare alert reference](https://developers.cloudflare.com/notifications/) for which fields your alert
  type honours.
- `alert_type` is validated against the full list in the provider schema. New alert types appear regularly, so
  a bump of the provider constraint may be needed before a new one can be used.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the notification policies and webhook destinations. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | Notification policies (`cloudflare_notification_policy`), keyed by a stable identifier.<br/><br/>Every policy needs at least one delivery mechanism. `emails` are plain addresses, `pagerduty_ids` are<br/>connected PagerDuty service IDs, `webhook_keys` reference keys of `var.webhooks`, and `webhook_ids` reference<br/>webhook destinations this module does not manage.<br/><br/>`filters` narrows an alert to a subset of events. Which fields apply depends entirely on `alert_type`; see<br/>the Cloudflare alert reference. | <pre>map(object({<br/>    name           = string<br/>    alert_type     = string<br/>    description    = optional(string)<br/>    enabled        = optional(bool, true)<br/>    alert_interval = optional(string)<br/>    emails         = optional(list(string), [])<br/>    pagerduty_ids  = optional(list(string), [])<br/>    webhook_keys   = optional(list(string), [])<br/>    webhook_ids    = optional(list(string), [])<br/>    filters = optional(object({<br/>      actions                         = optional(list(string))<br/>      affected_asns                   = optional(list(string))<br/>      affected_components             = optional(list(string))<br/>      affected_locations              = optional(list(string))<br/>      airport_code                    = optional(list(string))<br/>      alert_trigger_preferences       = optional(list(string))<br/>      alert_trigger_preferences_value = optional(list(string))<br/>      enabled                         = optional(list(string))<br/>      environment                     = optional(list(string))<br/>      event                           = optional(list(string))<br/>      event_source                    = optional(list(string))<br/>      event_type                      = optional(list(string))<br/>      group_by                        = optional(list(string))<br/>      health_check_id                 = optional(list(string))<br/>      incident_impact                 = optional(list(string))<br/>      input_id                        = optional(list(string))<br/>      insight_class                   = optional(list(string))<br/>      limit                           = optional(list(string))<br/>      logo_tag                        = optional(list(string))<br/>      megabits_per_second             = optional(list(string))<br/>      new_health                      = optional(list(string))<br/>      new_status                      = optional(list(string))<br/>      packets_per_second              = optional(list(string))<br/>      pool_id                         = optional(list(string))<br/>      pop_names                       = optional(list(string))<br/>      product                         = optional(list(string))<br/>      project_id                      = optional(list(string))<br/>      protocol                        = optional(list(string))<br/>      query_tag                       = optional(list(string))<br/>      requests_per_second             = optional(list(string))<br/>      selectors                       = optional(list(string))<br/>      services                        = optional(list(string))<br/>      slo                             = optional(list(string))<br/>      status                          = optional(list(string))<br/>      target_hostname                 = optional(list(string))<br/>      target_ip                       = optional(list(string))<br/>      target_zone_name                = optional(list(string))<br/>      traffic_exclusions              = optional(list(string))<br/>      tunnel_id                       = optional(list(string))<br/>      tunnel_name                     = optional(list(string))<br/>      type                            = optional(list(string))<br/>      where                           = optional(list(string))<br/>      zones                           = optional(list(string))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Webhook destinations (`cloudflare_notification_policy_webhooks`), keyed by a stable identifier.<br/><br/>`secret` is passed in the `cf-webhook-auth` header. Cloudflare never returns it, so Terraform cannot detect<br/>drift on it. | <pre>map(object({<br/>    name   = string<br/>    url    = string<br/>    secret = optional(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_policies"></a> [policies](#output\_policies) | Map of created cloudflare\_notification\_policy resources, keyed as in var.policies. |
| <a name="output_policy_ids"></a> [policy\_ids](#output\_policy\_ids) | Map of notification policy IDs, keyed as in var.policies. |
| <a name="output_webhook_ids"></a> [webhook\_ids](#output\_webhook\_ids) | Map of webhook destination IDs, keyed as in var.webhooks. |
| <a name="output_webhooks"></a> [webhooks](#output\_webhooks) | Map of created cloudflare\_notification\_policy\_webhooks resources, keyed as in var.webhooks. |
<!-- END_TF_DOCS -->
