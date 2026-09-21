locals {
  component_names = {
    backendAddressPools           = "BackendPool"
    backendHttpSettingsCollection = "BackendHttp"
    frontendIPConfigurations      = "PublicFrontend"
    frontendPorts                 = "HttpPort"
    httpListeners                 = "HttpListener"
    probes                        = "HealthProbe"
  }
  expected_ids = {
    for type, name in local.component_names : type => "${local.gateway_id}/${type}/${name}"
  }
  gateway_id   = provider::azapi::build_resource_id(azapi_resource.resource_group.id, "Microsoft.Network/applicationGateways", local.gateway_name)
  gateway_name = "agw-ref-${random_id.suffix.hex}"
  references = {
    for type, name in local.component_names : type => {
      id   = var.use_reference_names ? null : local.expected_ids[type]
      name = var.use_reference_names ? lower(name) : null
    }
  }
}
