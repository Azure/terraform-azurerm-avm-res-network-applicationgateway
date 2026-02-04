locals {
  frontend_ip_configuration_name         = "${var.name}-feip"
  frontend_ip_configuration_private_name = "${var.name}-fepvt-ip"
  gateway_ip_configuration_name          = "${var.name}-gwipc"
  identity_required                      = var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0
  managed_identities = {
    type = (
      var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" :
      var.managed_identities.system_assigned ? "SystemAssigned" :
      "UserAssigned"
    )
    identity_ids = (
      length(var.managed_identities.user_assigned_resource_ids) > 0 ? var.managed_identities.user_assigned_resource_ids : null
    )
  }
  public_ip_address_configuration = {
    resource_group_name              = coalesce(var.public_ip_address_configuration.resource_group_name, var.resource_group_name)
    location                         = coalesce(var.public_ip_address_configuration.location, var.location)
    public_ip_resource_id            = try(var.public_ip_address_configuration.public_ip_resource_id, null)
    name                             = coalesce(var.public_ip_address_configuration.public_ip_name, "pip-${var.name}")
    sku                              = var.public_ip_address_configuration.sku
    sku_tier                         = var.public_ip_address_configuration.sku_tier
    zones                            = coalesce(var.public_ip_address_configuration.zones, var.zones)
    allocation_method                = var.public_ip_address_configuration.allocation_method
    ip_version                       = var.public_ip_address_configuration.ip_version
    ddos_protection_mode             = var.public_ip_address_configuration.ddos_protection_mode
    ddos_protection_plan_resource_id = try(var.public_ip_address_configuration.ddos_protection_plan_resource_id, null)
    public_ip_prefix_id              = try(var.public_ip_address_configuration.public_ip_prefix_resource_id, null)
    domain_name_label                = try(var.public_ip_address_configuration.domain_name_label, null)
    reverse_fqdn                     = try(var.public_ip_address_configuration.reverse_fqdn, null)
    idle_timeout_in_minutes          = var.public_ip_address_configuration.idle_timeout_in_minutes
    tags                             = coalesce(var.public_ip_address_configuration.tags, var.tags)

  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
