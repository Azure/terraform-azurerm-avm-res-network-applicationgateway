variable "ignore_body_changes" {
  type = object({
    authorization_locks           = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
    network_application_gateways  = optional(list(string), [])
    network_private_endpoints     = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups = optional(object({
      network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
    }), {})
    network_public_ip_addresses = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths to ignore. Ignored configuration is not sent to Azure until the path is removed. Changes take effect only after apply. List indices are not supported.

- `network_application_gateways` - Paths ignored on the Application Gateway.
- `network_private_endpoints` - Paths ignored on each private endpoint.
- `network_private_endpoints_private_dns_zone_groups` - Paths passed to each private DNS zone group submodule.
- `network_private_endpoints_private_dns_zone_groups.network_private_endpoints_private_dns_zone_groups` - Paths ignored on each private DNS zone group.
- `authorization_locks` - Paths ignored on each private endpoint lock.
- `authorization_role_assignments` - Paths ignored on each private endpoint role assignment.
- `network_public_ip_addresses` - Paths ignored on each module-managed public IP.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for path in concat(
        var.ignore_body_changes.authorization_locks,
        var.ignore_body_changes.authorization_role_assignments,
        var.ignore_body_changes.network_application_gateways,
        var.ignore_body_changes.network_private_endpoints,
        var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups.network_private_endpoints_private_dns_zone_groups,
        var.ignore_body_changes.network_public_ip_addresses
      ) :
      path == null ? false : trimspace(path) != "" && !can(regex("[\\[\\]]", path))
    ])
    error_message = "ignore_body_changes paths must be non-empty dot-notation strings without list indices."
  }
}

variable "resource_types" {
  type = object({
    authorization_locks           = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    network_application_gateways   = optional(string, "Microsoft.Network/applicationGateways@2025-03-01")
    network_private_endpoints      = optional(string, "Microsoft.Network/privateEndpoints@2025-03-01")
    network_private_endpoints_private_dns_zone_groups = optional(object({
      network_private_endpoints_private_dns_zone_groups = optional(string)
    }), {})
    network_public_ip_addresses = optional(string, "Microsoft.Network/publicIPAddresses@2025-03-01")
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions. Override only where the selected API supports the configured properties.

- `network_application_gateways` - Resource type and API version for the Application Gateway.
- `network_private_endpoints` - Resource type and API version for private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Resource-type overrides passed to the private DNS zone group submodule.
- `network_private_endpoints_private_dns_zone_groups.network_private_endpoints_private_dns_zone_groups` - Resource type and API-version override for private DNS zone groups.
- `authorization_locks` - Resource type and API version for private endpoint locks.
- `authorization_role_assignments` - Resource type and API version for private endpoint role assignments.
- `network_public_ip_addresses` - Resource type and API version for module-managed public IPs.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
Retry configuration applied to the Application Gateway, module-managed public IPs, private endpoints, DNS zone groups, locks, and role assignments. Defaults to the provider's retry behavior.

- `error_message_regex` - Error patterns eligible for retry.
- `interval_seconds` - Initial retry interval.
- `max_interval_seconds` - Maximum retry interval.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Per-operation timeouts applied to the Application Gateway, module-managed public IPs, private endpoints, DNS zone groups, locks, and role assignments. Omitted values use provider defaults.

- `create` - Creation timeout, as a Go duration such as `1h`.
- `read` - Read timeout.
- `update` - Update timeout.
- `delete` - Deletion timeout.
DESCRIPTION
}
