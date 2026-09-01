variable "enabled" {
  description = "Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID used by account scoped Logpush jobs and ownership challenges."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Default Cloudflare zone ID for zone scoped Logpush jobs. An entry may override it."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "ownership_challenges" {
  description = <<-EOT
    Ownership challenges (`cloudflare_logpush_ownership_challenge`), keyed by a stable identifier.

    Cloudflare writes a challenge file to the destination and the token in that file must be fed back as the
    job's `ownership_challenge`. `destination_conf` frequently embeds credentials in the URL, so this variable
    is marked sensitive.
  EOT

  type = map(object({
    destination_conf = string
    zone_id          = optional(string)
    account_scoped   = optional(bool, true)
  }))
  default   = {}
  sensitive = true
}

variable "jobs" {
  description = <<-EOT
    Logpush jobs (`cloudflare_logpush_job`), keyed by a stable identifier.

    **This variable is sensitive.** `destination_conf` carries the sink URL, and for S3, GCS, Azure and similar
    sinks that URL embeds an access key or a signed token. The provider marks the attribute SENSITIVE and so
    does every output here, but the value still lands in Terraform state. Treat state as a secret.

    A job is zone scoped when `zone_id` is set (or `var.zone_id` is set and `account_scoped` is false), and
    account scoped otherwise. Cloudflare rejects a job that carries both.

    Reference an ownership challenge either by `ownership_challenge_key` (a key of `var.ownership_challenges`)
    or by passing the literal token as `ownership_challenge`.
  EOT

  type = map(object({
    dataset                     = string
    destination_conf            = string
    name                        = optional(string)
    enabled                     = optional(bool, true)
    filter                      = optional(string)
    kind                        = optional(string)
    zone_id                     = optional(string)
    account_scoped              = optional(bool, true)
    max_upload_bytes            = optional(number)
    max_upload_interval_seconds = optional(number)
    max_upload_records          = optional(number)
    ownership_challenge         = optional(string)
    ownership_challenge_key     = optional(string)
    output_options = optional(object({
      batch_prefix      = optional(string)
      batch_suffix      = optional(string)
      cve_2021_44228    = optional(bool)
      field_delimiter   = optional(string)
      field_names       = optional(list(string))
      merge_subrequests = optional(bool)
      output_type       = optional(string)
      record_delimiter  = optional(string)
      record_prefix     = optional(string)
      record_suffix     = optional(string)
      record_template   = optional(string)
      sample_rate       = optional(number)
      timestamp_format  = optional(string)
    }))
  }))
  default   = {}
  sensitive = true

  validation {
    condition = alltrue([
      for j in values(var.jobs) : j.kind == null || contains(["", "edge"], coalesce(j.kind, ""))
    ])
    error_message = "Each job kind must be one of \"\" (Logpush) or \"edge\" (Edge Log Delivery)."
  }

  validation {
    condition = alltrue([
      for j in values(var.jobs) :
      j.output_options == null || j.output_options.output_type == null ||
      contains(["ndjson", "csv"], coalesce(try(j.output_options.output_type, null), "ndjson"))
    ])
    error_message = "Each job output_options.output_type must be one of ndjson, csv."
  }

  validation {
    condition = alltrue([
      for j in values(var.jobs) :
      j.output_options == null || j.output_options.timestamp_format == null ||
      contains(["unixnano", "unix", "rfc3339", "rfc3339ms", "rfc3339ns"], coalesce(try(j.output_options.timestamp_format, null), "unixnano"))
    ])
    error_message = "Each job output_options.timestamp_format must be one of unixnano, unix, rfc3339, rfc3339ms, rfc3339ns."
  }

  validation {
    condition = alltrue([
      for j in values(var.jobs) :
      !(j.ownership_challenge != null && j.ownership_challenge_key != null)
    ])
    error_message = "A job may set ownership_challenge or ownership_challenge_key, but not both."
  }

  validation {
    condition = alltrue([
      for j in values(var.jobs) :
      j.max_upload_interval_seconds == null || j.max_upload_interval_seconds == 0 ||
      (j.max_upload_interval_seconds >= 30 && j.max_upload_interval_seconds <= 300)
    ])
    error_message = "max_upload_interval_seconds must be 0 to disable it, or between 30 and 300 seconds."
  }

  validation {
    condition = alltrue([
      for j in values(var.jobs) :
      j.max_upload_records == null || j.max_upload_records == 0 ||
      (j.max_upload_records >= 1000 && j.max_upload_records <= 1000000)
    ])
    error_message = "max_upload_records must be 0 to disable it, or between 1000 and 1000000 lines."
  }
}

variable "logpull_retention" {
  description = <<-EOT
    Logpull retention flags (`cloudflare_logpull_retention`), keyed by a stable identifier. Retention is a
    per zone setting, so each entry names its own zone or falls back to `var.zone_id`.
  EOT

  type = map(object({
    zone_id = optional(string)
    flag    = optional(bool, true)
  }))
  default = {}
}
