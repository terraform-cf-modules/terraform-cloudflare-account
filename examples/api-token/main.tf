# API tokens, which are the least obvious part of this module.
#
# A token's reach is the product of two things: the permission groups it names
# and the resource scopes those permissions apply to. Both are opaque IDs, and
# neither is discoverable from the provider schema.
#
#   permission_group_ids  what the token may do. List them with
#                         GET /accounts/{account_id}/tokens/permission_groups
#   resources             where it may do it. A map of scope string to value.
#                         "com.cloudflare.api.account.<account_id>"       = "*"
#                         "com.cloudflare.api.account.zone.<zone_id>"     = "*"
#                         "com.cloudflare.api.account.zone.*"             = "*"
#
# The `policies` input is a map so a policy can be added or removed without
# shifting the others in state.
#
# The token value is disclosed by the API exactly once, at creation. It is stored
# in Terraform state and every output carrying it is marked sensitive.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../modules/api-token"

  enabled    = true
  account_id = var.account_id

  account_tokens = {
    # A CI token that may edit DNS in one zone and read analytics account wide.
    ci = {
      name       = "ci-dns"
      status     = "active"
      expires_on = "2027-01-01T00:00:00Z"

      # Only accept the token from the CI egress range.
      request_ip_in = ["203.0.113.0/24"]

      policies = {
        dns_edit = {
          effect               = "allow"
          permission_group_ids = [var.dns_write_permission_group_id]
          resources = {
            "com.cloudflare.api.account.zone.${var.zone_id}" = "*"
          }
        }

        analytics_read = {
          effect               = "allow"
          permission_group_ids = [var.analytics_read_permission_group_id]
          resources = {
            "com.cloudflare.api.account.${var.account_id}" = "*"
          }
        }
      }
    }
  }

  user_tokens = {
    # A user scoped token using the raw JSON escape hatch, for scopes the simple
    # map form cannot express.
    break_glass = {
      name = "break-glass"

      policies = {
        everything = {
          effect               = "allow"
          permission_group_ids = [var.dns_write_permission_group_id]
          resources_json = jsonencode({
            "com.cloudflare.api.account.${var.account_id}" = {
              "com.cloudflare.api.account.zone.*" = "*"
            }
          })
        }
      }
    }
  }
}
