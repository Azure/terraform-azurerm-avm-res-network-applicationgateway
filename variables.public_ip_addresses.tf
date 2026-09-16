variable "public_ip_addresses" {
  type = map(object({
    name                             = string
    ddos_protection_mode             = optional(string, "VirtualNetworkInherited")
    ddos_protection_plan_resource_id = optional(string)
    domain_name_label                = optional(string)
    idle_timeout_in_minutes          = optional(number, 4)
    ip_tags                          = optional(map(string), {})
    ip_version                       = optional(string, "IPv4")
    parent_id                        = optional(string)
    public_ip_prefix_resource_id     = optional(string)
    reverse_fqdn                     = optional(string)
    tags                             = optional(map(string), {})
    zones                            = optional(list(string))
  }))
  default     = {}
  description = <<DESCRIPTION
Public IP addresses owned by this module. The default empty map creates no public IPs. Map keys must be known at plan time and are stable Terraform instance keys, independent of Azure names. Reference a key using `frontend_ip_configurations[*].public_ip_address_key`.

Each entry supports:
- `name` - Required Azure public IP name.
- `ip_version` - `IPv4` (default) or `IPv6`. At most one managed IP per protocol is supported.
- `parent_id` - Existing resource group ID. Defaults to the gateway's `parent_id`. The IP always uses the gateway's location.
- `zones` - Defaults to the gateway's zones. An explicit empty list leaves zone selection to Azure. A non-empty selection must include every gateway zone.
- `tags` - Per-IP tags merged over the module's tags.
- `public_ip_prefix_resource_id` - Optional existing public IP prefix ID. The prefix must be compatible with the IP's location, protocol and zones.
- `ddos_protection_mode` - `VirtualNetworkInherited` (default), `Enabled`, or `Disabled`.
- `ddos_protection_plan_resource_id` - Optional existing DDoS plan ID; requires `Enabled`. `Enabled` without a plan uses individual IP protection.
- `domain_name_label` - Optional Azure-managed DNS label.
- `reverse_fqdn` - Optional reverse DNS FQDN; supported for IPv4 only.
- `idle_timeout_in_minutes` - Integer from 4 to 30, default 4.
- `ip_tags` - IP tag type to tag value mapping, separate from resource tags.

Managed IPs use the Standard SKU, Regional tier and Static allocation. Prefixes, DDoS plans and resource groups are not created. Removing an entry schedules its IP for deletion; transferring ownership requires explicit state migration. See UPGRADE.md.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for ip in values(var.public_ip_addresses) : ip != null])
    error_message = "Each public_ip_addresses entry must be an object, not null."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : can(regex("^[a-zA-Z0-9]([a-zA-Z0-9_.-]{0,78}[a-zA-Z0-9_])?$", ip.name))
    ])
    error_message = "Each public IP name must be 1-80 characters, start with an alphanumeric character, contain only alphanumeric characters, underscores, periods or hyphens, and end with an alphanumeric character or underscore."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : contains(["IPv4", "IPv6"], ip.ip_version)
    ])
    error_message = "Each public_ip_addresses.ip_version must be IPv4 or IPv6."
  }
  validation {
    condition = length(distinct([
      for ip in values(var.public_ip_addresses) : ip.ip_version if ip != null
    ])) == length([for ip in values(var.public_ip_addresses) : ip if ip != null])
    error_message = "Application Gateway supports at most one managed public IP per IP version."
  }
  validation {
    condition = length(distinct([
      for ip in values(var.public_ip_addresses) :
      lower("${coalesce(ip.parent_id, var.parent_id)}/${ip.name}")
      if ip == null ? false : ip.name != null
      ])) == length([
      for ip in values(var.public_ip_addresses) : ip
      if ip == null ? false : ip.name != null
    ])
    error_message = "Managed public IPs must have distinct Azure names within each resource group."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.parent_id == null ? true : can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", ip.parent_id))
    ])
    error_message = "Each public_ip_addresses.parent_id must be a valid resource group resource ID."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.public_ip_prefix_resource_id == null ? true : can(provider::azapi::parse_resource_id("Microsoft.Network/publicIPPrefixes", ip.public_ip_prefix_resource_id))
    ])
    error_message = "Each public_ip_prefix_resource_id must be a valid public IP prefix resource ID."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.ddos_protection_plan_resource_id == null ? true : can(provider::azapi::parse_resource_id("Microsoft.Network/ddosProtectionPlans", ip.ddos_protection_plan_resource_id))
    ])
    error_message = "Each ddos_protection_plan_resource_id must be a valid DDoS protection plan resource ID."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : contains(["VirtualNetworkInherited", "Enabled", "Disabled"], ip.ddos_protection_mode)
    ])
    error_message = "Each ddos_protection_mode must be VirtualNetworkInherited, Enabled or Disabled."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.ddos_protection_plan_resource_id == null || ip.ddos_protection_mode == "Enabled"
    ])
    error_message = "A ddos_protection_plan_resource_id requires ddos_protection_mode = \"Enabled\"."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.idle_timeout_in_minutes >= 4 && ip.idle_timeout_in_minutes <= 30 && floor(ip.idle_timeout_in_minutes) == ip.idle_timeout_in_minutes
    ])
    error_message = "Each idle_timeout_in_minutes must be an integer between 4 and 30."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.zones == null ? true : (
        length(distinct(ip.zones)) == length(ip.zones) &&
        alltrue([for zone in ip.zones : zone == null ? false : contains(["1", "2", "3"], zone)])
      )
    ])
    error_message = "Each public IP zones list must contain unique values from \"1\", \"2\" and \"3\", or be empty."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.zones == null ? true : length(ip.zones) == 0 ? true : length(setsubtract(coalesce(var.zones, []), ip.zones)) == 0
    ])
    error_message = "An explicit non-empty public IP zones list must include all gateway zones."
  }
  validation {
    condition = alltrue([
      for ip in values(var.public_ip_addresses) :
      ip == null ? true : ip.reverse_fqdn == null || ip.ip_version == "IPv4"
    ])
    error_message = "reverse_fqdn is supported only for IPv4 public IP addresses."
  }
  validation {
    condition = alltrue(flatten([
      for ip in values(var.public_ip_addresses) : ip == null ? [] : [
        for type, tag in ip.ip_tags : tag == null ? false : trimspace(type) != "" && trimspace(tag) != ""
      ]
    ]))
    error_message = "Public IP tag types and values must be non-empty strings."
  }
}
