# Submodule: dns-settings

Account wide DNS defaults and DNS Firewall resolver clusters.

| Resource | Purpose |
|----------|---------|
| `cloudflare_account_dns_settings` | The one set of account wide DNS defaults. |
| `cloudflare_dns_firewall` | A DNS Firewall resolver cluster. |

```hcl
module "dns_settings" {
  source  = "terraform-cf-modules/account/cloudflare//modules/dns-settings"
  version = "~> 0.1"

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
  }

  dns_firewalls = {
    corp_resolver = {
      name               = "corp-resolver"
      upstream_ips       = ["203.0.113.10", "203.0.113.11"]
      minimum_cache_ttl  = 60
      maximum_cache_ttl  = 900
      negative_cache_ttl = 60

      attack_mitigation = {
        enabled = true
      }
    }
  }
}
```

## Notes

- **There is exactly one `cloudflare_account_dns_settings` per account**, so it is a `count` guarded singleton
  behind `var.create_dns_settings`, which defaults to `false`. Two modules managing it in the same account will
  fight.
- `zone_defaults` applies to zones created **after** it is set. Existing zones keep their own settings.
- `enforce_dns_only` does not modify records. It changes how proxied records are served at the edge, and it
  applies account wide.
- **`dns_firewall_ip_count` is create only.** Cloudflare reads it when the cluster is created and it cannot be
  changed afterwards. Cloudflare assigns the actual resolver IPs, exposed on the `dns_firewall_ips` output.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID whose DNS defaults and DNS Firewall clusters this submodule manages. | `string` | `null` | no |
| <a name="input_create_dns_settings"></a> [create\_dns\_settings](#input\_create\_dns\_settings) | Whether to manage the account level DNS settings (`cloudflare_account_dns_settings`). There is exactly one per account. | `bool` | `false` | no |
| <a name="input_dns_firewalls"></a> [dns\_firewalls](#input\_dns\_firewalls) | DNS Firewall clusters (`cloudflare_dns_firewall`), keyed by a stable identifier.<br/><br/>`dns_firewall_ip_count` is only read when the cluster is created and cannot be changed afterwards. | <pre>map(object({<br/>    name                   = string<br/>    upstream_ips           = set(string)<br/>    deprecate_any_requests = optional(bool)<br/>    dns_firewall_ip_count  = optional(number)<br/>    ecs_fallback           = optional(bool)<br/>    maximum_cache_ttl      = optional(number)<br/>    minimum_cache_ttl      = optional(number)<br/>    negative_cache_ttl     = optional(number)<br/>    ratelimit              = optional(number)<br/>    retries                = optional(number)<br/>    attack_mitigation = optional(object({<br/>      enabled                      = optional(bool)<br/>      only_when_upstream_unhealthy = optional(bool)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_enforce_dns_only"></a> [enforce\_dns\_only](#input\_enforce\_dns\_only) | Force every proxied DNS record in the account to be served DNS-only at the edge, without changing the records themselves. | `bool` | `null` | no |
| <a name="input_zone_defaults"></a> [zone\_defaults](#input\_zone\_defaults) | Account wide defaults applied to newly created zones. Only used when `var.create_dns_settings` is true. | <pre>object({<br/>    flatten_all_cnames  = optional(bool)<br/>    foundation_dns      = optional(bool)<br/>    multi_provider      = optional(bool)<br/>    ns_ttl              = optional(number)<br/>    secondary_overrides = optional(bool)<br/>    zone_mode           = optional(string)<br/>    internal_dns = optional(object({<br/>      reference_zone_id = optional(string)<br/>    }))<br/>    nameservers = optional(object({<br/>      type = optional(string)<br/>    }))<br/>    soa = optional(object({<br/>      expire  = optional(number)<br/>      min_ttl = optional(number)<br/>      mname   = optional(string)<br/>      refresh = optional(number)<br/>      retry   = optional(number)<br/>      rname   = optional(string)<br/>      ttl     = optional(number)<br/>    }))<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dns_firewall_ids"></a> [dns\_firewall\_ids](#output\_dns\_firewall\_ids) | Map of DNS Firewall cluster IDs, keyed as in var.dns\_firewalls. |
| <a name="output_dns_firewall_ips"></a> [dns\_firewall\_ips](#output\_dns\_firewall\_ips) | Map of the resolver IPs Cloudflare assigned to each DNS Firewall cluster, keyed as in var.dns\_firewalls. |
| <a name="output_dns_firewalls"></a> [dns\_firewalls](#output\_dns\_firewalls) | Map of created cloudflare\_dns\_firewall resources, keyed as in var.dns\_firewalls. |
| <a name="output_dns_settings"></a> [dns\_settings](#output\_dns\_settings) | The cloudflare\_account\_dns\_settings resource, or null when not managed. |
| <a name="output_dns_settings_account_id"></a> [dns\_settings\_account\_id](#output\_dns\_settings\_account\_id) | Account ID of the managed DNS settings, or null when not managed. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
<!-- END_TF_DOCS -->
