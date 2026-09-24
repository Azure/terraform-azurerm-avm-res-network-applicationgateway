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
  reference_key_attributes = {
    backendAddressPools           = "backend_address_pool_key"
    backendHttpSettingsCollection = "backend_http_settings_key"
    frontendIPConfigurations      = "frontend_ip_configuration_key"
    frontendPorts                 = "frontend_port_key"
    httpListeners                 = "http_listener_key"
    probes                        = "probe_key"
  }
  references = {
    for type, name in local.component_names : type => {
      id                                     = var.use_reference_keys ? null : local.expected_ids[type]
      (local.reference_key_attributes[type]) = var.use_reference_keys ? lower(name) : null
    }
  }
}
