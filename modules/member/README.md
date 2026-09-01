# Submodule: member

Account members, user groups, and the mapping between them.

| Resource | Purpose |
|----------|---------|
| `cloudflare_account_member` | An invited human or service identity on the account. |
| `cloudflare_user_group` | A named bundle of policies. |
| `cloudflare_user_group_members` | The members attached to a user group. |

```hcl
module "member" {
  source  = "terraform-cf-modules/account/cloudflare//modules/member"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  members = {
    platform_lead = {
      email = "platform@example.com"
      roles = [var.administrator_role_id]
    }

    auditor = {
      email = "audit@example.com"

      policies = [{
        access               = "allow"
        permission_group_ids = [var.audit_read_permission_group_id]
        resource_group_ids   = [var.account_resource_group_id]
      }]
    }
  }

  groups = {
    network_engineers = {
      name = "Network engineers"

      policies = [{
        access               = "allow"
        permission_group_ids = [var.dns_write_permission_group_id]
        resource_group_ids   = [var.account_resource_group_id]
      }]
    }
  }

  group_members = {
    network_engineers = {
      group_key   = "network_engineers"
      member_keys = ["platform_lead"]
    }
  }
}
```

## Notes

- **Roles or policies, never both.** Cloudflare rejects a member that carries legacy role IDs and scoped
  policies at the same time. The module validates this before the API does.
- **Role, permission group, and resource group IDs are opaque.** They are not in the provider schema. Read them
  from `GET /accounts/{account_id}/roles`, `GET /accounts/{account_id}/tokens/permission_groups`, and the
  resource groups API.
- **Changing a member's `status` from `accepted` back to `pending` replaces the resource.** That re-sends the
  invitation.
- `group_members` references a group by `group_key` (a key of `var.groups`) or by `user_group_id` for a group
  this module does not manage, and members by `member_keys` or `member_ids`. The key form creates the
  dependency for you.

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
| [cloudflare_account_member.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/account_member) | resource |
| [cloudflare_user_group.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/user_group) | resource |
| [cloudflare_user_group_members.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/user_group_members) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the members and user groups. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. Set to false to disable the submodule without removing the block. | `bool` | `true` | no |
| <a name="input_group_members"></a> [group\_members](#input\_group\_members) | Membership of user groups, keyed by a stable identifier.<br/><br/>Reference a group either by `group_key` (a key of `var.groups`) or by `user_group_id` for a group this module<br/>does not manage. Reference members either by `member_keys` (keys of `var.members`) or by `member_ids`. | <pre>map(object({<br/>    group_key     = optional(string)<br/>    user_group_id = optional(string)<br/>    member_keys   = optional(list(string), [])<br/>    member_ids    = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_groups"></a> [groups](#input\_groups) | User groups to create, keyed by a stable identifier. Policies grant the group its permissions. | <pre>map(object({<br/>    name = string<br/>    policies = optional(list(object({<br/>      access               = string<br/>      permission_group_ids = list(string)<br/>      resource_group_ids   = list(string)<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_members"></a> [members](#input\_members) | Account members to invite, keyed by a stable identifier.<br/><br/>Supply either `roles` (a set of Cloudflare role IDs) or `policies`, not both. The Cloudflare API rejects a<br/>member that carries legacy roles and scoped policies at the same time. | <pre>map(object({<br/>    email  = string<br/>    roles  = optional(set(string))<br/>    status = optional(string)<br/>    policies = optional(list(object({<br/>      access               = string<br/>      permission_group_ids = list(string)<br/>      resource_group_ids   = list(string)<br/>    })))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_group_ids"></a> [group\_ids](#output\_group\_ids) | Map of user group IDs, keyed as in var.groups. |
| <a name="output_group_member_ids"></a> [group\_member\_ids](#output\_group\_member\_ids) | Map of user group membership IDs, keyed as in var.group\_members. |
| <a name="output_group_members"></a> [group\_members](#output\_group\_members) | Map of created cloudflare\_user\_group\_members resources, keyed as in var.group\_members. |
| <a name="output_groups"></a> [groups](#output\_groups) | Map of created cloudflare\_user\_group resources, keyed as in var.groups. |
| <a name="output_member_ids"></a> [member\_ids](#output\_member\_ids) | Map of account member IDs, keyed as in var.members. |
| <a name="output_members"></a> [members](#output\_members) | Map of created cloudflare\_account\_member resources, keyed as in var.members. |
<!-- END_TF_DOCS -->
