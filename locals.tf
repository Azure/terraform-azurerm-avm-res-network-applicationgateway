locals {
  frontend_ip_configuration_additional_public_ip_names = { for pip, pip_params in var.frontend_ip_configuration_additional_public_ips : pip => pip_params.name == null ? "${pip}-fepip" : pip_params.name }
  frontend_ip_configuration_name                       = "${var.name}-feip"
  frontend_ip_configuration_private_name               = "${var.name}-fepvt-ip"
  gateway_ip_configuration_name                        = "${var.name}-gwipc"
  identity_required                                    = var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0
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
  public_ip_name                     = "pip-${var.name}"
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
