# -----------------------------------------------------------------------------
# Submodule: member
#
# Account members, user groups, and the mapping between them.
#
#   cloudflare_account_member      an invited human or service identity
#   cloudflare_user_group          a named bundle of policies
#   cloudflare_user_group_members  the members attached to a user group
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  members       = local.enabled ? var.members : {}
  groups        = local.enabled ? var.groups : {}
  group_members = local.enabled ? var.group_members : {}
}

resource "cloudflare_account_member" "this" {
  for_each = local.members

  account_id = var.account_id
  email      = each.value.email
  roles      = each.value.roles
  status     = each.value.status

  policies = each.value.policies == null ? null : [
    for p in each.value.policies : {
      access            = p.access
      permission_groups = [for id in p.permission_group_ids : { id = id }]
      resource_groups   = [for id in p.resource_group_ids : { id = id }]
    }
  ]
}

resource "cloudflare_user_group" "this" {
  for_each = local.groups

  account_id = var.account_id
  name       = each.value.name

  policies = each.value.policies == null ? null : [
    for p in each.value.policies : {
      access            = p.access
      permission_groups = [for id in p.permission_group_ids : { id = id }]
      resource_groups   = [for id in p.resource_group_ids : { id = id }]
    }
  ]
}

resource "cloudflare_user_group_members" "this" {
  for_each = local.group_members

  account_id    = var.account_id
  user_group_id = each.value.user_group_id != null ? each.value.user_group_id : cloudflare_user_group.this[each.value.group_key].id

  members = [
    for id in concat(
      [for k in each.value.member_keys : cloudflare_account_member.this[k].id],
      each.value.member_ids,
    ) : { id = id }
  ]
}
