variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
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
  default     = null
  description = "The Azure region where the resources will be deployed. If you do not specify a location, the resource group location will be used."
  validation {
    condition     = var.location == null || length(var.location) > 0
    error_message = "The Azure region must not be empty."
  }
}

# Variable declaration for the  resource location
variable "virtual_network_resource_id" {
  type        = string
  description = "The resource id of the virtual network where the Application Gateway resources will be deployed."
  validation {
    condition     = can(regex("(?i:^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$)", var.frontend_subnet_resource_id))
    error_message = "The virtual network resource id must ve a valid Azure resource id."
  }
}

# Variable declaration for the  resource location
variable "frontend_subnet_resource_id" {
  type        = string
  description = "The resource id of the frontend subnet where the Application Gateway IP address resources will be deployed."
  validation {
    error_message = "The frontend subnet resource id must ve a valid Azure resource id."
    condition     = can(regex("(?i:^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$)", var.frontend_subnet_resource_id))
  }
}

# Variable declaration for the  resource location
variable "backend_subnet_resource_id" {
  type        = string
  description = "The backend subnet where the Application Gateway resources configuration will be deployed."
  validation {
    error_message = "The backend subnet resource id must ve a valid Azure resource id."
    condition     = can(regex("(?i:^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$)", var.frontend_subnet_resource_id))
  }
}

# Variable declaration for the  application gateway name
variable "name" {
  type        = string
  description = "The name of the Application Gateway."
  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.app_gateway_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

# Variable declaration for the  public ip name

variable "public_ip_name" {
  type        = string
  description = "The name of the public IP address."
  default     = null
  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.public_ip_name))
    error_message = "The name must be between 3 and 24 characters long and can only contain lowercase letters, numbers and dashes."
  }
}

# Variable declaration for the Log Analytics Workspace ID

variable "log_analytics_workspace_id" {
  type        = string
  description = "The Log Analytics Workspace ID"
  validation {
    condition     = length(var.log_analytics_workspace_id) > 0
    error_message = "The Log Analytics Workspace ID is required to configure the diagnostic settings."
  }
}

# Variable declaration for the  public  ip sku
variable "public_ip_sku_tier" {
  type        = string
  description = "The Azure public ip sku. Either Basic or Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku_tier)
    error_message = "The value must be either Basic, Standard"
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
  description = "The Application Gateway sku and tier."
  type = object({
    name     = string                 // Standard_Small, Standard_Medium, Standard_Large, Standard_v2, WAF_Medium, WAF_Large, and WAF_v2
    tier     = string                 // Standard, Standard_v2, WAF and WAF_v2
    capacity = optional(number, null) // V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU
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
    min_capacity = number           // Minimum in the range 0 to 100
    max_capacity = optional(number) // Maximum in the range 2 to 125
  })
  default = null
}


# HTTP/2 protocol support is available to clients that connect to application gateway listeners only.
# The communication to backend server pools is over HTTP/1.1. By default, HTTP/2 support is disabled.

variable "http2_enabled" {
  type        = bool
  description = "Enable or disable HTTP/2 protocol support. Default is `true`."
  default     = true
}

variable "zones" {
  type        = list(string)
  description = "The Azure application gateway deployment zones. Only supported on v2 SKUs. Default is zone redundant."
  default     = [1, 2, 3]
}

# Variable declaration for the backend address pool name
variable "backend_address_pools" {
  description = "List of backend address pools"
  type = list(object({
    name         = string
    fqdns        = optional(list(string))
    ip_addresses = optional(list(string))
  }))
}

variable "backend_http_settings" {
  description = "List of backend HTTP settings"
  type = list(object({
    name                  = string
    port                  = number
    protocol              = string
    cookie_based_affinity = string
    # affinity_cookie_name  = optional(string)
    # enable_https = bool

    # Define other attributes as needed
  }))
}

variable "http_listeners" {
  description = "List of HTTP listeners"
  type = list(object({
    name                   = string
    frontend_port_name     = string
    protocol               = string
    firewall_policy_id     = optional(string)
    frontend_ip_assocation = string
    host_name              = optional(string)
    host_names             = optional(list(string))
    ssl_certificate_name   = optional(string)
    ssl_profile_name       = optional(string)
    custom_error_configuration = optional(list(object({
      status_code           = string
      custom_error_page_url = string
    })))
    # Define other attributes as needed
  }))
}

variable "app_gateway_waf_policy_name" {
  type = string

  default = null
}


# Define a list of probe configurations
variable "probe_configurations" {
  description = "List of probe configurations."
  type = list(object({
    name                                      = string
    host                                      = optional(string)
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
  default = []
}


# Define a list of URL path map configurations
variable "url_path_map_configurations" {
  description = "List of URL path map configurations."
  type = list(object({
    name                                = string
    default_redirect_configuration_name = optional(string)
    default_rewrite_rule_set_name       = optional(string)
    default_backend_http_settings_name  = optional(string)
    default_backend_address_pool_name   = optional(string)
    path_rules = list(object({
      name                        = string
      paths                       = list(string)
      backend_address_pool_name   = optional(string)
      backend_http_settings_name  = optional(string)
      redirect_configuration_name = optional(string)
      rewrite_rule_set_name       = optional(string)
      firewall_policy_id          = optional(string)
    }))
  }))
  default = []
}

# Define a list of redirection configuration
variable "redirection_configurations" {
  description = "List of redirection configurations."
  type = list(object({
    name                 = string
    redirect_type        = string
    target_url           = string
    include_path         = optional(bool)
    include_query_string = optional(bool)

  }))
  default = []
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
  type = object({
    disabled_protocols   = optional(list(string))
    policy_type          = optional(string)
    policy_name          = optional(string)
    cipher_suites        = optional(list(string))
    min_protocol_version = optional(string)
  })
  default = null
}

variable "user_managed_identity_ids" {
  description = "Specifies a list with a single user managed identity id to be assigned to the Application Gateway"
  default     = null
}

variable "authentication_certificates" {
  description = "Authentication certificates to allow the backend with Azure Application Gateway"
  type = list(object({
    name = string
    data = string
  }))
  default  = []
  nullable = false
}

variable "trusted_root_certificates" {
  description = "Trusted root certificates to allow the backend with Azure Application Gateway"
  type = list(object({
    name = string
    data = string
  }))
  default  = []
  nullable = false
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

#  variable "frontend_ip_association" {
#   type = string
#   default = "public"
#  }


# Variable declaration for the request routing rules
variable "request_routing_rules" {
  description = "List of request routing rules"
  type = list(object({
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

variable "private_ip_address" {
  description = "Private IP Address to assign to the Application Gateway Load Balancer."
  type        = string
  default     = null
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

variable "classic_rule_enabled" {
  type        = bool
  description = "Enable or disable the classic WAF rules. Default is `false`."
  default     = false
}
