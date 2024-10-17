# Variable declaration for the backend address pool name 
variable "backend_address_pools" {
  type = map(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
  description = "List of backend address pools"
}

variable "backend_http_settings" {
  type = map(object({
    name                                = string
    cookie_based_affinity               = string
    path                                = optional(string)
    affinity_cookie_name                = optional(string)
    port                                = optional(number)
    enable_https                        = bool
    probe_name                          = optional(string)
    request_timeout                     = number
    host_name                           = optional(string)
    pick_host_name_from_backend_address = optional(bool)
    authentication_certificate = optional(object({
      name = string
    }))
    trusted_root_certificate_names = optional(list(string))
    connection_draining = optional(object({
      enable_connection_draining = bool
      drain_timeout_sec          = number
    }))
  }))
  description = "List of backend HTTP settings "
}

# # Variable declaration for the frontend ports
variable "frontend_ports" {
  type = map(object({
    name = string
    port = number

  }))
  description = "Map of frontend ports"
}

variable "http_listeners" {
  type = map(object({
    name               = string
    frontend_port_name = string

    firewall_policy_id   = optional(string)
    require_sni          = optional(bool)
    host_name            = optional(string)
    host_names           = optional(list(string))
    ssl_certificate_name = optional(string)
    ssl_profile_name     = optional(string)
    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })))
    # Define other attributes as needed
  }))
  description = "List of HTTP listeners"
}

# Variable declaration for the  resource location
variable "location" {
  type        = string
  description = "The Azure regional location where the resources will be deployed."
  nullable    = false

  validation {
    condition     = length(var.location) > 0
    error_message = "The azure region must not be empty."
  }
}

# Variable declaration for the  application gateway name
variable "name" {
  type        = string
  description = "The name of the application gateway."

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "public_ip_name" {
  type        = string
  description = "The name of the application gateway."

  validation {
    #58 Updated the regex to allow for longer names to char 80
    condition     = can(regex("^[a-z0-9-]{3,80}$", var.public_ip_name))
    error_message = "The name must be between 3 and 80 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

variable "request_routing_rules" {
  type = map(object({
    name                        = string
    rule_type                   = string
    http_listener_name          = string
    backend_address_pool_name   = optional(string)
    priority                    = optional(number)
    url_path_map_name           = optional(string)
    backend_http_settings_name  = optional(string)
    redirect_configuration_name = optional(string)
    rewrite_rule_set_name       = optional(string)
    # Define other attributes as needed
  }))
  description = "List of request routing rules"
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "The resource group name must not be empty."
  }
}

# Variable declaration for the  resource location
variable "subnet_name_backend" {
  type        = string
  description = "The backend subnet where the application gateway resources configuration will be deployed."

  validation {
    condition     = length(var.subnet_name_backend) > 0
    error_message = "The backend subnet name must not be empty."
  }
}

# Variable declaration for the  resource location
variable "vnet_name" {
  type        = string
  description = "The VNET where the application gateway resources will be deployed."

  validation {
    condition     = length(var.vnet_name) > 0
    error_message = "The VNET name must not be empty."
  }
}

# This is required for most resource modules
#54 Added the variable for the vnet resource group name 
#Customer would like to deploy AGW and Subnet in different resource group
variable "vnet_resource_group_name" {
  type        = string
  description = "The resource group where the VNET resources deployed."

  validation {
    condition     = length(var.vnet_resource_group_name) > 0
    error_message = "The resource group name must not be empty."
  }
}

variable "app_gateway_waf_policy_resource_id" {
  type        = string
  default     = null
  description = "The ID of the WAF policy to associate with the Application Gateway."
}

variable "autoscale_configuration" {
  type = object({
    min_capacity = optional(number, 1) # Minimum in the range 0 to 100
    max_capacity = optional(number, 2) # Maximum in the range 2 to 125
  })
  default     = null
  description = "V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU"
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
A map of diagnostic settings to create on the ddos protection plan. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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

variable "enable_classic_rule" {
  type        = bool
  default     = false
  description = "Enable or disable the classic WAF rule"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetry.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "frontend_ip_type" {
  type        = string
  default     = "public"
  description = "Type of frontend IP configuration. Possible values: 'public', 'private', 'both'"

  validation {
    condition     = can(regex("^(public|private|both)$", var.frontend_ip_type))
    error_message = "frontend_ip_type must be either 'public', 'private', or 'both'."
  }
}

variable "http2_enable" {
  type        = bool
  default     = true
  description = "The Azure application gateway HTTP/2 protocol support"
}

variable "identity_ids" {
  type        = list(string)
  default     = []
  description = "Specifies a list with a single user managed identity id to be assigned to the Application Gateway"
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "private_ip_address" {
  type        = string
  default     = null
  description = "Private IP Address to assign to the Application Gateway Load Balancer."
}

# Define a list of probe configurations
variable "probe_configurations" {
  type = map(object({
    name                                      = string
    host                                      = string
    interval                                  = number
    timeout                                   = number
    unhealthy_threshold                       = number
    protocol                                  = string
    port                                      = optional(number)
    path                                      = string
    pick_host_name_from_backend_http_settings = optional(bool)
    minimum_servers                           = optional(number)
    match = optional(object({
      body        = optional(string)
      status_code = optional(list(string))
    }))
  }))
  default     = null
  description = "List of probe configurations."
}

# Define a list of redirection configuration
variable "redirect_configuration" {
  type = map(object({
    name                 = string
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool)
    include_query_string = optional(bool)

  }))
  default     = null
  description = "List of redirection configurations."
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
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

# Variable declaration for the application gateway sku and tier
variable "sku" {
  type = object({
    name     = string              # Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2
    tier     = string              # Standard, Standard_v2, WAF and WAF_v2
    capacity = optional(number, 2) # V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU
  })
  default = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  description = "The application gateway sku and tier."

  validation {
    condition     = can(regex("^(Standard_v2|WAF_v2)$", var.sku.name))
    error_message = "SKU name must be 'Standard_v2' or 'WAF_v2'."
  }
  validation {
    condition     = can(regex("^(Standard_v2|WAF_v2)$", var.sku.tier))
    error_message = "SKU tier must be 'Standard_v2' or 'WAF_v2'."
  }
}

variable "ssl_certificates" {
  type = list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default     = []
  description = "List of SSL certificates data for Application gateway"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A map of tags to apply to the Application Gateway."
}

# Define a list of URL path map configurations
variable "url_path_map_configurations" {
  type = map(object({
    name                                = string
    default_redirect_configuration_name = optional(string)
    default_rewrite_rule_set_name       = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_backend_address_pool_name   = optional(string)
    path_rules = map(object({
      name                        = string
      paths                       = list(string)
      backend_address_pool_name   = optional(string)
      backend_http_settings_name  = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
      firewall_policy_id          = optional(string)
    }))
  }))
  default     = null
  description = "List of URL path map configurations."
}

variable "waf_configuration" {
  type = list(object({
    enabled          = bool
    firewall_mode    = string
    rule_set_type    = string
    rule_set_version = string
    # disabled_rule_groups = list(string)
  }))
  default     = null
  description = "Web Application Firewall (WAF) configuration."
}

variable "zones" {
  type        = list(string)
  default     = ["1", "2", "3"] #["1", "2", "3"]
  description = "The Azure application gateway zone redundancy"
}
