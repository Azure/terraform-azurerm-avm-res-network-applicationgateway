variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-_.]{0,78}[a-zA-Z0-9_]$", var.name))
    error_message = "The name must be 2-80 characters, start and end with a letter or number, and contain only letters, numbers, hyphens, underscores, and periods."
  }
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `"CanNotDelete"` and `"ReadOnly"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      name                                   = optional(string, null)
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind  = string
      name  = optional(string, null)
      notes = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = optional(string, null)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
      member_name        = optional(string)
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create for the Application Gateway. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time. Each endpoint connects to the Application Gateway `appGateway` private-link subresource. Configure a gateway-side private link configuration and attach it to a frontend before creating endpoints. The gateway must have at least one public frontend; private-only gateways are unsupported.

The private endpoint subnet must differ from the Application Gateway subnet and have private endpoint network policies disabled. When multiple frontends are linked to private link configurations, set `ip_configurations` to identify the frontend member.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
  - `name` - (Optional) The name of the role assignment. If not set, a UUID is generated.
- `lock` - (Optional) The lock to apply to the private endpoint. Possible values are `CanNotDelete` and `ReadOnly`.
  - `notes` - (Optional) Notes about the lock.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `subresource_name` - (Optional) The private endpoint subresource name. Application Gateway supports only `appGateway`; this is the default.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. Defaults to `default`.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_associations` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys may be unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. Defaults to a generated name.
- `network_interface_name` - (Optional) The name of the network interface. Defaults to a generated name.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the Application Gateway location.
- `resource_group_name` - Not supported; private endpoints are created in the Application Gateway resource group.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
  - `member_name` - The name of a frontend associated with the gateway-side private link configuration.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for endpoint in values(var.private_endpoints) :
      endpoint != null && can(provider::azapi::parse_resource_id("Microsoft.Network/virtualNetworks/subnets", endpoint.subnet_resource_id))
    ])
    error_message = "Each private_endpoints[*].subnet_resource_id must be a valid subnet resource ID."
  }
  validation {
    condition = alltrue(flatten([
      for endpoint in values(var.private_endpoints) : endpoint == null ? [] : [
        for id in endpoint.private_dns_zone_resource_ids :
        can(provider::azapi::parse_resource_id("Microsoft.Network/privateDnsZones", id))
      ]
    ]))
    error_message = "Each private_endpoints[*].private_dns_zone_resource_ids entry must be a valid private DNS zone resource ID."
  }
  validation {
    condition = alltrue(flatten([
      for endpoint in values(var.private_endpoints) : endpoint == null ? [] : [
        for id in values(endpoint.application_security_group_associations) :
        can(provider::azapi::parse_resource_id("Microsoft.Network/applicationSecurityGroups", id))
      ]
    ]))
    error_message = "Each private_endpoints[*].application_security_group_associations value must be a valid application security group resource ID."
  }
  validation {
    condition = alltrue(flatten([
      for endpoint in values(var.private_endpoints) : endpoint == null ? [] : [
        for assignment in values(endpoint.role_assignments) :
        assignment == null ? false : assignment.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", assignment.delegated_managed_identity_resource_id))
      ]
    ]))
    error_message = "Each private_endpoints[*].role_assignments[*].delegated_managed_identity_resource_id must be a valid user-assigned managed identity resource ID, or null."
  }
  validation {
    condition = alltrue([
      for endpoint in values(var.private_endpoints) :
      endpoint == null ? true : endpoint.subresource_name == null || endpoint.subresource_name == "appGateway"
    ])
    error_message = "Application Gateway private endpoints support only the appGateway subresource."
  }
  validation {
    condition = alltrue([
      for endpoint in values(var.private_endpoints) :
      endpoint == null ? true : endpoint.resource_group_name == null
    ])
    error_message = "Private endpoints must be deployed in the Application Gateway resource group; resource_group_name overrides are not supported."
  }
  validation {
    condition = alltrue([
      for endpoint in values(var.private_endpoints) :
      endpoint == null ? true : endpoint.lock == null || contains(["CanNotDelete", "ReadOnly"], endpoint.lock.kind)
    ])
    error_message = "Each private endpoint lock kind must be CanNotDelete or ReadOnly."
  }
  validation {
    condition = length(var.private_endpoints) == 0 || (
      var.sku != null &&
      contains(["Standard_v2", "WAF_v2"], var.sku.name) &&
      length(coalesce(var.private_link_configurations, [])) > 0 &&
      anytrue([
        for frontend in coalesce(var.frontend_ip_configurations, []) :
        frontend != null &&
        frontend.private_link_configuration != null
      ]) &&
      anytrue([
        for frontend in coalesce(var.frontend_ip_configurations, []) :
        frontend != null &&
        (try(frontend.public_ip_address.id, null) != null || frontend.public_ip_address_key != null)
      ])
    )
    error_message = "Private endpoints require a Standard_v2 or WAF_v2 gateway with a gateway-side private link configuration and at least one public frontend. Private-only gateways are not supported."
  }
  validation {
    condition = alltrue(flatten([
      for endpoint in values(var.private_endpoints) : endpoint == null ? [] : [
        for ip_configuration in values(endpoint.ip_configurations) :
        ip_configuration != null && ip_configuration.member_name != null && anytrue([
          for frontend in coalesce(var.frontend_ip_configurations, []) :
          frontend != null &&
          frontend.name != null &&
          lower(frontend.name) == try(lower(ip_configuration.member_name), "") &&
          frontend.private_link_configuration != null
        ])
      ]
    ]))
    error_message = "Each private endpoint IP configuration must specify a member_name matching a frontend attached to a gateway-side private link configuration."
  }
  validation {
    condition = length(var.private_endpoints) == 0 || alltrue([
      for endpoint in values(var.private_endpoints) :
      endpoint == null ? false : length([
        for frontend in coalesce(var.frontend_ip_configurations, []) :
        frontend
        if frontend != null &&
        frontend.private_link_configuration != null
      ]) <= 1 || length(endpoint.ip_configurations) > 0
    ])
    error_message = "When multiple frontends are attached to gateway-side private link configurations, each private endpoint must specify ip_configurations to identify its frontend member."
  }
  validation {
    condition = alltrue(flatten([
      for endpoint in values(var.private_endpoints) : endpoint == null ? [] : [
        for gateway_ip_configuration in coalesce(var.gateway_ip_configurations, []) :
        try(lower(gateway_ip_configuration.subnet.id), "") != try(lower(endpoint.subnet_resource_id), "")
      ]
    ]))
    error_message = "A private endpoint subnet must be different from every Application Gateway subnet."
  }
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If false, DNS zone groups must be managed externally."
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
