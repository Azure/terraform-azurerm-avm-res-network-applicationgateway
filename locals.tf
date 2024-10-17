locals {
  frontend_ip_configuration_name         = "${var.name}-feip"
  frontend_ip_configuration_private_name = "${var.name}-fepvt-ip"
  gateway_ip_configuration_name          = "${var.name}-gwipc"
  managed_identities = {
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
