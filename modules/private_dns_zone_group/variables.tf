variable "name" {
  type        = string
  description = "The name of the private DNS zone group."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The fully-qualified ARM resource ID of the private endpoint that contains the private DNS zone group."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/privateEndpoints", var.parent_id))
    error_message = "`parent_id` must be a valid private endpoint resource ID."
  }
}

variable "body" {
  type = object({
    properties = object({
      privateDnsZoneConfigs = list(object({
        name = string
        properties = object({
          privateDnsZoneId = string
        })
      }))
    })
  })
  description = "The private DNS zone group properties."
  nullable    = false
}

variable "resource_types" {
  type = object({
    network_private_endpoints_private_dns_zone_groups = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2025-03-01")
  })
  default     = {}
  description = "AzAPI resource type and API version for the private DNS zone group."
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
  })
  default     = {}
  description = "Body-relative paths ignored on the private DNS zone group. Paths use dot notation; changes take effect only after apply."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Retry configuration applied to the private DNS zone group."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Per-operation timeouts applied to the private DNS zone group."
}
