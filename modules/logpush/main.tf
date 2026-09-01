# -----------------------------------------------------------------------------
# Submodule: logpush
#
#   cloudflare_logpush_ownership_challenge  proves you control the destination
#   cloudflare_logpush_job                  the export itself
#   cloudflare_logpull_retention            per zone Logpull retention flag
#
# var.jobs and var.ownership_challenges are marked sensitive because
# destination_conf commonly embeds credentials (an S3 access key, an Azure SAS
# token, a Splunk HEC token). Terraform refuses a sensitive value as for_each, so
# each local below builds a view with destination_conf blanked out, unmarks that,
# and drives for_each from it. The real destination_conf is read straight from
# the variable at the point of use and keeps its sensitivity.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  challenges = local.enabled ? nonsensitive({
    for k, v in var.ownership_challenges : k => merge(v, { destination_conf = null })
  }) : {}

  jobs = local.enabled ? nonsensitive({
    for k, v in var.jobs : k => merge(v, { destination_conf = null })
  }) : {}

  logpull_retention = local.enabled ? var.logpull_retention : {}
}

resource "cloudflare_logpush_ownership_challenge" "this" {
  for_each = local.challenges

  destination_conf = var.ownership_challenges[each.key].destination_conf

  # Cloudflare rejects a challenge that carries both scopes, so resolve to exactly one.
  zone_id    = each.value.zone_id != null ? each.value.zone_id : (each.value.account_scoped ? null : var.zone_id)
  account_id = each.value.zone_id != null || !each.value.account_scoped ? null : var.account_id
}

resource "cloudflare_logpush_job" "this" {
  for_each = local.jobs

  dataset          = each.value.dataset
  destination_conf = var.jobs[each.key].destination_conf
  name             = each.value.name
  enabled          = each.value.enabled
  filter           = each.value.filter
  kind             = each.value.kind

  max_upload_bytes            = each.value.max_upload_bytes
  max_upload_interval_seconds = each.value.max_upload_interval_seconds
  max_upload_records          = each.value.max_upload_records

  output_options = each.value.output_options

  ownership_challenge = (
    each.value.ownership_challenge_key != null
    ? cloudflare_logpush_ownership_challenge.this[each.value.ownership_challenge_key].filename
    : each.value.ownership_challenge
  )

  # Cloudflare rejects a job that carries both scopes, so resolve to exactly one.
  zone_id    = each.value.zone_id != null ? each.value.zone_id : (each.value.account_scoped ? null : var.zone_id)
  account_id = each.value.zone_id != null || !each.value.account_scoped ? null : var.account_id
}

resource "cloudflare_logpull_retention" "this" {
  for_each = local.logpull_retention

  zone_id = coalesce(each.value.zone_id, var.zone_id)
  flag    = each.value.flag
}
