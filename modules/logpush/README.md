# Submodule: logpush

Log export to an external sink, plus the per zone Logpull retention flag.

| Resource | Purpose |
|----------|---------|
| `cloudflare_logpush_ownership_challenge` | Proves you control the destination before a job may write to it. |
| `cloudflare_logpush_job` | The export itself. |
| `cloudflare_logpull_retention` | Per zone Logpull retention flag. |

```hcl
module "logpush" {
  source  = "terraform-cf-modules/account/cloudflare//modules/logpush"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id
  zone_id    = var.zone_id

  ownership_challenges = {
    audit_bucket = {
      destination_conf = var.destination_conf
    }
  }

  jobs = {
    audit_logs = {
      dataset                 = "audit_logs"
      destination_conf        = var.destination_conf
      name                    = "audit-logs"
      ownership_challenge_key = "audit_bucket"

      max_upload_interval_seconds = 60
      max_upload_records          = 10000

      output_options = {
        output_type      = "ndjson"
        timestamp_format = "rfc3339"
        field_names      = ["ActorEmail", "ActionType", "When"]
        cve_2021_44228   = true
      }
    }
  }
}
```

## `destination_conf` carries credentials

This is the reason `var.jobs` and `var.ownership_challenges` are both marked `sensitive = true`.

For S3, GCS, Azure Blob, Splunk, Sumo Logic and Datadog sinks the access key, SAS token or HEC token is part of
the destination URL:

```
s3://my-bucket/logs?region=eu-west-1&access-key-id=AKIA...&secret-access-key=...
```

What that means in practice:

- The provider schema marks `destination_conf` `SENSITIVE`, so it is redacted in plan output.
- `var.jobs` and `var.ownership_challenges` are marked sensitive here, so the value is redacted anywhere it
  flows through the module.
- The `jobs`, `ownership_challenges` and `ownership_challenge_filenames` outputs are `sensitive = true`. The
  `job_ids` output is not, because an ID is not a secret.
- **It still lands in Terraform state.** Treat state as a secret, keep it in an encrypted backend, and supply
  the value through `TF_VAR_` or a data source rather than committing it.

Terraform refuses a sensitive value as a `for_each` argument. The module works around that by building a view
of the map with `destination_conf` blanked out, unmarking that view, and driving `for_each` from it. The real
value is read straight from the variable at the point of use and keeps its sensitivity.

## Ownership challenges

Cloudflare writes a challenge file into the destination before it will accept a job for it. The token in that
file goes back as the job's `ownership_challenge`. Declare the challenge in `var.ownership_challenges` and
reference it from the job with `ownership_challenge_key`, and the dependency is expressed for you. Pass a
literal token with `ownership_challenge` instead if you obtained it out of band.

## Scope

A Logpush job is account scoped **or** zone scoped, never both. Cloudflare rejects a job carrying both IDs.

| You want | Set |
|----------|-----|
| Account scoped (default) | nothing; `var.account_id` is used |
| Zone scoped | `zone_id` on the entry, or `account_scoped = false` with a module level `var.zone_id` |

`cloudflare_logpull_retention` is always per zone, so each entry names its own zone or falls back to
`var.zone_id`.

The deprecated `frequency` and `logpull_options` attributes are deliberately not exposed. Use `max_upload_bytes`,
`max_upload_interval_seconds`, `max_upload_records` and `output_options` instead.

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
| [cloudflare_logpull_retention.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/logpull_retention) | resource |
| [cloudflare_logpush_job.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/logpush_job) | resource |
| [cloudflare_logpush_ownership_challenge.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/logpush_ownership_challenge) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID used by account scoped Logpush jobs and ownership challenges. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_jobs"></a> [jobs](#input\_jobs) | Logpush jobs (`cloudflare_logpush_job`), keyed by a stable identifier.<br/><br/>**This variable is sensitive.** `destination_conf` carries the sink URL, and for S3, GCS, Azure and similar<br/>sinks that URL embeds an access key or a signed token. The provider marks the attribute SENSITIVE and so<br/>does every output here, but the value still lands in Terraform state. Treat state as a secret.<br/><br/>A job is zone scoped when `zone_id` is set (or `var.zone_id` is set and `account_scoped` is false), and<br/>account scoped otherwise. Cloudflare rejects a job that carries both.<br/><br/>Reference an ownership challenge either by `ownership_challenge_key` (a key of `var.ownership_challenges`)<br/>or by passing the literal token as `ownership_challenge`. | <pre>map(object({<br/>    dataset                     = string<br/>    destination_conf            = string<br/>    name                        = optional(string)<br/>    enabled                     = optional(bool, true)<br/>    filter                      = optional(string)<br/>    kind                        = optional(string)<br/>    zone_id                     = optional(string)<br/>    account_scoped              = optional(bool, true)<br/>    max_upload_bytes            = optional(number)<br/>    max_upload_interval_seconds = optional(number)<br/>    max_upload_records          = optional(number)<br/>    ownership_challenge         = optional(string)<br/>    ownership_challenge_key     = optional(string)<br/>    output_options = optional(object({<br/>      batch_prefix      = optional(string)<br/>      batch_suffix      = optional(string)<br/>      cve_2021_44228    = optional(bool)<br/>      field_delimiter   = optional(string)<br/>      field_names       = optional(list(string))<br/>      merge_subrequests = optional(bool)<br/>      output_type       = optional(string)<br/>      record_delimiter  = optional(string)<br/>      record_prefix     = optional(string)<br/>      record_suffix     = optional(string)<br/>      record_template   = optional(string)<br/>      sample_rate       = optional(number)<br/>      timestamp_format  = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_logpull_retention"></a> [logpull\_retention](#input\_logpull\_retention) | Logpull retention flags (`cloudflare_logpull_retention`), keyed by a stable identifier. Retention is a<br/>per zone setting, so each entry names its own zone or falls back to `var.zone_id`. | <pre>map(object({<br/>    zone_id = optional(string)<br/>    flag    = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_ownership_challenges"></a> [ownership\_challenges](#input\_ownership\_challenges) | Ownership challenges (`cloudflare_logpush_ownership_challenge`), keyed by a stable identifier.<br/><br/>Cloudflare writes a challenge file to the destination and the token in that file must be fed back as the<br/>job's `ownership_challenge`. `destination_conf` frequently embeds credentials in the URL, so this variable<br/>is marked sensitive. | <pre>map(object({<br/>    destination_conf = string<br/>    zone_id          = optional(string)<br/>    account_scoped   = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Default Cloudflare zone ID for zone scoped Logpush jobs. An entry may override it. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_job_ids"></a> [job\_ids](#output\_job\_ids) | Map of Logpush job IDs, keyed as in var.jobs. |
| <a name="output_jobs"></a> [jobs](#output\_jobs) | Map of created cloudflare\_logpush\_job resources, keyed as in var.jobs. Sensitive because destination\_conf can embed credentials. |
| <a name="output_logpull_retention"></a> [logpull\_retention](#output\_logpull\_retention) | Map of created cloudflare\_logpull\_retention resources, keyed as in var.logpull\_retention. |
| <a name="output_logpull_retention_ids"></a> [logpull\_retention\_ids](#output\_logpull\_retention\_ids) | Map of Logpull retention resource IDs, keyed as in var.logpull\_retention. |
| <a name="output_ownership_challenge_filenames"></a> [ownership\_challenge\_filenames](#output\_ownership\_challenge\_filenames) | Map of the challenge file names Cloudflare wrote to each destination, keyed as in var.ownership\_challenges. |
| <a name="output_ownership_challenges"></a> [ownership\_challenges](#output\_ownership\_challenges) | Map of created cloudflare\_logpush\_ownership\_challenge resources, keyed as in var.ownership\_challenges. |
<!-- END_TF_DOCS -->
