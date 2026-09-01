# Architecture

This module is the one a platform team runs once per Cloudflare account. The root module handles the account
object, the people who can reach it, and the baseline alerts that tell them when something is wrong. Everything
else is a building block under `modules/` that a caller composes as needed.

## Resource map

| Terraform resource | Cloudflare object | Created by |
|--------------------|-------------------|------------|
| `cloudflare_account` | The account itself | root |
| `cloudflare_account_member` | Invited member | `modules/member` (called by root) |
| `cloudflare_user_group` | User group | `modules/member` (called by root) |
| `cloudflare_user_group_members` | Group membership | `modules/member` (called by root) |
| `cloudflare_notification_policy_webhooks` | Webhook destination | `modules/notification` (called by root) |
| `cloudflare_notification_policy` | Alert policy | `modules/notification` (called by root) |
| `cloudflare_api_token` | User scoped API token | `modules/api-token` |
| `cloudflare_account_token` | Account scoped API token | `modules/api-token` |
| `cloudflare_logpush_ownership_challenge` | Destination ownership proof | `modules/logpush` |
| `cloudflare_logpush_job` | Log export job | `modules/logpush` |
| `cloudflare_logpull_retention` | Per zone Logpull retention flag | `modules/logpush` |
| `cloudflare_secrets_store` | Secrets store | `modules/secrets-store` |
| `cloudflare_secrets_store_secret` | Secret inside a store | `modules/secrets-store` |
| `cloudflare_account_dns_settings` | Account wide DNS defaults | `modules/dns-settings` |
| `cloudflare_dns_firewall` | DNS Firewall resolver cluster | `modules/dns-settings` |
| `cloudflare_share` | Cross account share | `modules/sharing` |
| `cloudflare_share_recipient` | Recipient added after creation | `modules/sharing` |
| `cloudflare_share_resource` | Resource added after creation | `modules/sharing` |

The root module calls `modules/member` and `modules/notification` only. The other five are not called from the
root because they are not part of "bootstrap an account": tokens, log export, secrets, DNS defaults and sharing
are decisions a team makes separately, often in a different state file with a different blast radius.

## Scope

Account scoped. `var.account_id` is the anchor for almost everything.

The root module takes no `zone_id`, because nothing it creates is zone scoped. `modules/logpush` is the only
submodule with a zone anchor: `cloudflare_logpull_retention` is per zone, and `cloudflare_logpush_job` may be
either account or zone scoped.

When `var.create_account = true` the root creates the account and every downstream resource anchors on the new
account's ID, which is unknown until apply. Account creation through the API requires a tenant or reseller
relationship, so most callers leave this false and pass an existing `var.account_id`.

## Ordering and dependencies

All of these are implicit through references. There is no `depends_on` anywhere in this repository.

| Before | After | Why |
|--------|-------|-----|
| `cloudflare_account` | everything else | `local.account_id` reads its ID |
| `cloudflare_user_group` | `cloudflare_user_group_members` | membership references the group ID |
| `cloudflare_account_member` | `cloudflare_user_group_members` | membership references member IDs |
| `cloudflare_notification_policy_webhooks` | `cloudflare_notification_policy` | mechanisms reference webhook IDs |
| `cloudflare_logpush_ownership_challenge` | `cloudflare_logpush_job` | the job's `ownership_challenge` reads the challenge filename |
| `cloudflare_secrets_store` | `cloudflare_secrets_store_secret` | the secret references the store ID |
| `cloudflare_share` | `cloudflare_share_recipient`, `cloudflare_share_resource` | both reference the share ID |

Each of these is expressed by referencing a **key** rather than an ID: `group_key`, `member_keys`,
`webhook_keys`, `ownership_challenge_key`, `store_key`, `share_key`. Pass the corresponding `*_id` instead when
the target is not managed by this module, and the dependency simply does not exist.

## Known provider quirks

**Deprecated attributes that this module deliberately does not expose.** `cloudflare_account.type`
("The 'type' field should no longer be set through the API"), and `cloudflare_logpush_job.frequency` and
`logpull_options`. Terraform still emits a "Deprecated value used" warning when an output reads the whole
resource object, because the deprecated attribute is part of that object. The warning is unavoidable while the
module honours the organisation rule to output the full resource, and it is harmless.

**Mutually exclusive scope on Logpush.** `cloudflare_logpush_job` and `cloudflare_logpush_ownership_challenge`
both accept `account_id` and `zone_id` as optional, but Cloudflare rejects a request carrying both. The module
resolves to exactly one before the value reaches the provider.

**Roles and policies are mutually exclusive on a member.** The schema marks both optional and says nothing about
the interaction. Cloudflare rejects the combination. `modules/member` validates it.

**Sensitive maps cannot drive `for_each`.** `var.jobs`, `var.secrets` and `var.webhooks` all carry secret
material and are marked sensitive, and Terraform refuses a marked value as a `for_each` argument. Each of those
submodules builds an unmarked view with the secret field blanked out, drives `for_each` from that, and reads the
real secret straight from the variable at the point of use.

**`cloudflare_api_token` policies take `resources` as a JSON string**, not an object, and the permission group
and resource group IDs behind it are opaque values that appear nowhere in the provider schema. Read them from
`GET /accounts/{account_id}/tokens/permission_groups`.

**Token values are disclosed once.** `cloudflare_api_token.value` and `cloudflare_account_token.value` are
`computed` and `SENSITIVE`. Cloudflare returns the value only at creation and there is no way to read it back,
so it exists in Terraform state or nowhere.

**Write only secrets never drift.** `cloudflare_secrets_store_secret.value` and
`cloudflare_notification_policy_webhooks.secret` are never returned by the API, so Terraform cannot detect that
someone changed them out of band.

**`cloudflare_notification_policy.filters` is one 43 field object for every alert type.** Each alert type reads
only a few of the fields and silently ignores the rest. The module passes the object straight through; check the
Cloudflare alert reference for which fields your `alert_type` honours.

**There is exactly one `cloudflare_account_dns_settings` per account.** It is guarded behind
`var.create_dns_settings`, defaulting to false, so two states do not fight over it.

**`cloudflare_dns_firewall.dns_firewall_ip_count` is create only.** It is read when the cluster is created and
cannot be changed later.
