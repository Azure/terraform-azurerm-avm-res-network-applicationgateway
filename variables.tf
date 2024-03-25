variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetry.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# **Prerequisites:** values for the following variables must be set in the local.tf file

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
variable "location" {
  type        = string
  description = "The Azure regional location where the resources will be deployed."
  validation {
    condition     = length(var.location) > 0
    error_message = "The azure region must not be empty."
  }
}

# Variable declaration for the  resource location
variable "vnet_name" {

  description = "The VNET where the applicaiton gateway resources will be deployed."
  validation {
    condition     = length(var.vnet_name) > 0
    error_message = "The VNET name must not be empty."
  }
}

# Variable declaration for the  resource location
variable "subnet_name_frontend" {
  type        = string
  description = "The frontend subnet where the applicaiton gateway IP address resources will be deployed."
  validation {
    condition     = length(var.subnet_name_frontend) > 0
    error_message = "The frontend subnet name must not be empty."
  }
}

# Variable declaration for the  resource location
variable "subnet_name_backend" {
  type        = string
  description = "The backend subnet where the applicaiton gateway resources configuration will be deployed."
  validation {
    condition     = length(var.subnet_name_backend) > 0
    error_message = "The backend subnet name must not be empty."
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

# Variable declaration for the  public ip name

variable "public_ip_name" {
  type        = string
  description = "The name of the application gateway."
  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.public_ip_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

# Variable declaration for the Log Analytics Workspace ID

# variable "log_analytics_workspace_id" {
#   type        = string
#   description = "The Log Analytics Workspace ID"
#   validation {
#     condition     = length(var.log_analytics_workspace_id) > 0
#     error_message = "The Log Analytics Workspace ID is required to configure the diagnostic settings."
#   }
# }

# Variable declaration for the  public  ip sku
variable "public_ip_sku_tier" {
  type        = string
  description = "The Azure public ip sku Basic / Standard"
  validation {
    condition     = var.public_ip_sku_tier == "Basic" || var.public_ip_sku_tier == "Standard"
    error_message = "The variable must be either Basic, Standard"
  }
  default = "Standard"
}

# Variable declaration for the  public  ip allocation method
variable "public_ip_allocation_method" {
  type        = string
  description = "The Azure public allocation method dynamic / static"

  validation {
    condition     = var.public_ip_allocation_method == "Dynamic" || var.public_ip_allocation_method == "Static"
    error_message = "The variable must be either Dynamic or Static"
  }
  default = "Static"
}

# Variable declaration for the application gateway sku and tier
variable "sku" {
  description = "The application gateway sku and tier."
  type = object({
    name     = string           // Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2
    tier     = string           // Standard, Standard_v2, WAF and WAF_v2
    capacity = optional(number) // V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU
  })
  validation {
    condition     = can(regex("^(Standard_v2|WAF_v2)$", var.sku.name))
    error_message = "SKU name must be 'Standard_v2' or 'WAF_v2'."
  }

  validation {
    condition     = can(regex("^(Standard_v2|WAF_v2)$", var.sku.tier))
    error_message = "SKU tier must be 'Standard_v2' or 'WAF_v2'."
  }
}

# variable for V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU

variable "autoscale_configuration" {
  description = "V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU"
  type = object({
    min_capacity = optional(number, 1) // Minimum in the range 0 to 100
    max_capacity = optional(number, 2) // Maximum in the range 2 to 125
  })
  default = null
}


# HTTP/2 protocol support is available to clients that connect to application gateway listeners only. 
# The communication to backend server pools is over HTTP/1.1. By default, HTTP/2 support is disabled.

variable "http2_enable" {
  type        = bool
  description = "The Azure application gateway HTTP/2 protocol support"
  default     = true
}

variable "zones" {
  type        = list(string)
  description = "The Azure application gateway zone redundancy"
  default     = [] #["1", "2", "3"]
}

# # Variable declaration for the frontend ports
variable "frontend_ports" {
  description = "Map of frontend ports"
  type = map(object({
    name = string
    port = number

  }))
}


# Variable declaration for the backend address pool name 
variable "backend_address_pools" {
  description = "List of backend address pools"
  type = map(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
}

variable "backend_http_settings" {
  description = "List of backend HTTP settings"
  type = map(object({
    name                                = string
    cookie_based_affinity               = string
    path                                = optional(string)
    affinity_cookie_name                = optional(string)
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
  # Define other attributes as needed
}

variable "http_listeners" {
  description = "List of HTTP listeners"
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
}

variable "request_routing_rules" {
  description = "List of request routing rules"
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
}

variable "app_gateway_waf_policy_resource_id" {
  type = string

  default = null
}


# Define a list of probe configurations
variable "probe_configurations" {
  description = "List of probe configurations."
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
  default = null
}


# Define a list of URL path map configurations
variable "url_path_map_configurations" {
  description = "List of URL path map configurations."
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
  default = null
}

# Define a list of redirection configuration
variable "redirect_configuration" {
  description = "List of redirection configurations."
  type = map(object({
    name                 = string
    redirect_type        = string
    target_listener_name = optional(string)
    target_url           = optional(string)
    include_path         = optional(bool)
    include_query_string = optional(bool)

  }))
  default = null
}

variable "ssl_certificates" {
  description = "List of SSL certificates data for Application gateway"
  type = list(object({
    name                = string
    data                = optional(string)
    password            = optional(string)
    key_vault_secret_id = optional(string)
  }))
  default = []
}

variable "ssl_policy" {
  description = "Application Gateway SSL configuration"
  type = map(object({
    disabled_protocols   = optional(list(string))
    policy_type          = optional(string)
    policy_name          = optional(string)
    cipher_suites        = optional(list(string))
    min_protocol_version = optional(string)
  }))
  default = null
}

variable "identity_ids" {
  description = "Specifies a list with a single user managed identity id to be assigned to the Application Gateway"
  default     = null
}

variable "authentication_certificates" {
  description = "Authentication certificates to allow the backend with Azure Application Gateway"
  type = list(object({
    name = string
    data = string
  }))
  default = []
}

variable "trusted_root_certificates" {
  description = "Trusted root certificates to allow the backend with Azure Application Gateway"
  type = list(object({
    name = string
    data = string
  }))
  default = []
}


# variable "rewrite_rule_set_configurations" {
#   description = "List of rewrite rule sets including rewrite rules"
#   type        = list(object({
#     name          = string
#     rewrite_rules = list(object({
#       name                    = string
#       rule_sequence           = number
#       condition               = list(object({
#         variable    = string
#         pattern     = string
#         ignore_case = bool
#         negate      = bool
#       }))
#       request_header_configuration = list(object({
#         header_name  = string
#         header_value = string
#       }))
#       response_header_configuration = list(object({
#         header_name  = string
#         header_value = string
#       }))
#       url = list(object({
#         path         = string
#         query_string = string
#         reroute      = string
#       }))
#     }))
#   }))
# default = []
# }

# variable "custom_error_configurations" {
#   description = "List of custom error configurations."
#   type        = list(object({
#     name         = string
#     status       = string
#     error_response = object({
#       custom_response = object({
#         response_html = string
#       })
#     })
#   }))
#    default     = []
# }

#  variable "frontend_ip_assocation" {
#   type = string
#   default = "public"
#  }


# Variable declaration for the request routing rules


variable "private_ip_address" {
  description = "Private IP Address to assign to the Application Gateway Load Balancer."
  type        = string
  default     = null
}

variable "frontend_ip_type" {
  description = "Type of frontend IP configuration. Possible values: 'public', 'private', 'both'"
  type        = string
  default     = "public"

  validation {
    condition     = can(regex("^(public|private|both)$", var.frontend_ip_type))
    error_message = "frontend_ip_type must be either 'public', 'private', or 'both'."
  }
}


variable "tags" {
  description = "A map of tags to apply to the Application Gateway."
  type        = map(string)
  default = {
    environment = "development"
    owner       = "your-name"
    project     = "my-project"
  }
}

variable "waf_enable" {
  description = "Enable or disable the Web Application Firewall"
  type        = bool
  default     = true
}

variable "waf_configuration" {
  description = "Web Application Firewall (WAF) configuration."
  type = list(object({
    enabled          = bool
    firewall_mode    = string
    rule_set_type    = string
    rule_set_version = string
    # disabled_rule_groups = list(string)
  }))
  default = null
}

# variable "waf_policy_name" {
#   type = string
#   description = "The name of the WAF policy."
# }

variable "enable_classic_rule" {
  type        = bool
  description = "Enable or disable the classic WAF rule"
  default     = false
}



# Variable declaration for the diagnostics, lock and role assignments settings 

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  description = "The lock level to apply to the deployed resource. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
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

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
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
  default  = {}
  nullable = false

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
}
