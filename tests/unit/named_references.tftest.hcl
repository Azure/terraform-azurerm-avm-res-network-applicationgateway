mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "westus2"
  name             = "Gateway"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
}

run "resolves_all_internal_reference_families" {
  command = apply

  variables {
    authentication_certificates = [{ name = "AuthCert" }]
    backend_address_pools       = [{ name = "BackendPool" }]
    backend_http_settings_collection = [{
      name = "BackendHttp"
      properties = {
        authentication_certificates = [{ authentication_certificate_key = "authcert" }]
        probe                       = { probe_key = "PROBE" }
        trusted_root_certificates   = [{ trusted_root_certificate_key = "rootcert" }]
      }
    }]
    backend_settings_collection = [{
      name = "BackendSetting"
      properties = {
        probe                     = { probe_key = "probe" }
        trusted_root_certificates = [{ trusted_root_certificate_key = "ROOTCERT" }]
      }
    }]
    entra_jwt_validation_configs = [{ name = "EntraConfig" }]
    frontend_ip_configurations = [{
      name = "FrontendIp"
      properties = {
        private_link_configuration = { private_link_configuration_key = "privatelink" }
        public_ip_address          = { id = "/opaque/public-ip" }
        subnet                     = { id = "/opaque/frontend-subnet" }
      }
    }]
    frontend_ports = [{ name = "FrontendPort", properties = { port = 443 } }]
    http_listeners = [{
      name = "HttpListener"
      properties = {
        firewall_policy           = { id = "/opaque/listener-policy" }
        frontend_ip_configuration = { frontend_ip_configuration_key = "frontendip" }
        frontend_port             = { frontend_port_key = "FRONTENDPORT" }
        ssl_certificate           = { ssl_certificate_key = "sslcert" }
        ssl_profile               = { ssl_profile_key = "SSLPROFILE" }
      }
    }]
    listeners = [{
      name = "Listener"
      properties = {
        frontend_ip_configuration = { frontend_ip_configuration_key = "FRONTENDIP" }
        frontend_port             = { frontend_port_key = "frontendport" }
        ssl_certificate           = { ssl_certificate_key = "SSLCERT" }
        ssl_profile               = { ssl_profile_key = "sslprofile" }
      }
    }]
    load_distribution_policies = [{
      name = "LoadPolicy"
      properties = {
        load_distribution_targets = [{
          id   = "/opaque/load-target-definition"
          name = "LoadTarget"
          properties = {
            backend_address_pool = { backend_address_pool_key = "backendpool" }
          }
        }]
      }
    }]
    private_link_configurations = [{
      name = "PrivateLink"
      properties = {
        ip_configurations = [{
          id   = "/opaque/private-link-ip-definition"
          name = "PrivateIp"
          properties = {
            subnet = { id = "/opaque/private-link-subnet" }
          }
        }]
      }
    }]
    probes = [{ name = "Probe" }]
    redirect_configurations = [{
      name = "Redirect"
      properties = {
        path_rules            = [{ path_rule_key = "PATHRULE", url_path_map_key = "pathmap" }]
        request_routing_rules = [{ request_routing_rule_key = "ROUTERULE" }]
        target_listener       = { http_listener_key = "httplistener" }
        url_path_maps         = [{ url_path_map_key = "PATHMAP" }]
      }
    }]
    request_routing_rules = [{
      name = "RouteRule"
      properties = {
        backend_address_pool        = { backend_address_pool_key = "BACKENDPOOL" }
        backend_http_settings       = { backend_http_settings_key = "backendhttp" }
        entra_jwt_validation_config = { entra_jwt_validation_config_key = "ENTRACONFIG" }
        http_listener               = { http_listener_key = "HTTPListener" }
        load_distribution_policy    = { load_distribution_policy_key = "loadpolicy" }
        redirect_configuration      = { redirect_configuration_key = "REDIRECT" }
        rewrite_rule_set            = { rewrite_rule_set_key = "rewriteset" }
        url_path_map                = { url_path_map_key = "pathmap" }
      }
    }]
    rewrite_rule_sets = [{ name = "RewriteSet" }]
    routing_rules = [{
      name = "RoutingRule"
      properties = {
        backend_address_pool = { backend_address_pool_key = "backendpool" }
        backend_settings     = { backend_settings_key = "BACKENDSETTING" }
        listener             = { listener_key = "listener" }
        priority             = 1
      }
    }]
    ssl_certificates = [{ name = "SslCert" }]
    ssl_profiles = [{
      name = "SslProfile"
      properties = {
        trusted_client_certificates = [{ trusted_client_certificate_key = "clientcert" }]
      }
    }]
    trusted_client_certificates = [{ name = "ClientCert" }]
    trusted_root_certificates   = [{ name = "RootCert" }]
    url_path_maps = [{
      name = "PathMap"
      properties = {
        default_backend_address_pool     = { backend_address_pool_key = "backendpool" }
        default_backend_http_settings    = { backend_http_settings_key = "BACKENDHTTP" }
        default_load_distribution_policy = { load_distribution_policy_key = "loadpolicy" }
        default_redirect_configuration   = { redirect_configuration_key = "redirect" }
        default_rewrite_rule_set         = { rewrite_rule_set_key = "REWRITESET" }
        path_rules = [{
          id   = "/opaque/path-rule-definition"
          name = "PathRule"
          properties = {
            backend_address_pool     = { backend_address_pool_key = "backendpool" }
            backend_http_settings    = { backend_http_settings_key = "backendhttp" }
            firewall_policy          = { id = "/opaque/path-rule-policy" }
            load_distribution_policy = { load_distribution_policy_key = "loadpolicy" }
            redirect_configuration   = { redirect_configuration_key = "redirect" }
            rewrite_rule_set         = { rewrite_rule_set_key = "rewriteset" }
          }
        }]
      }
    }]
  }

  assert {
    condition = alltrue([
      azapi_resource.this.body.properties.backendHttpSettingsCollection[0].properties.authenticationCertificates[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/authenticationCertificates/AuthCert",
      azapi_resource.this.body.properties.backendHttpSettingsCollection[0].properties.probe.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/probes/Probe",
      azapi_resource.this.body.properties.backendHttpSettingsCollection[0].properties.trustedRootCertificates[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/trustedRootCertificates/RootCert",
      azapi_resource.this.body.properties.backendSettingsCollection[0].properties.probe.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/probes/Probe",
      azapi_resource.this.body.properties.backendSettingsCollection[0].properties.trustedRootCertificates[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/trustedRootCertificates/RootCert",
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.privateLinkConfiguration.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/privateLinkConfigurations/PrivateLink",
      azapi_resource.this.body.properties.httpListeners[0].properties.frontendIPConfiguration.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/frontendIPConfigurations/FrontendIp",
      azapi_resource.this.body.properties.httpListeners[0].properties.frontendPort.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/frontendPorts/FrontendPort",
      azapi_resource.this.body.properties.httpListeners[0].properties.sslCertificate.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/sslCertificates/SslCert",
      azapi_resource.this.body.properties.httpListeners[0].properties.sslProfile.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/sslProfiles/SslProfile",
      azapi_resource.this.body.properties.listeners[0].properties.frontendIPConfiguration.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/frontendIPConfigurations/FrontendIp",
      azapi_resource.this.body.properties.listeners[0].properties.frontendPort.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/frontendPorts/FrontendPort",
      azapi_resource.this.body.properties.listeners[0].properties.sslCertificate.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/sslCertificates/SslCert",
      azapi_resource.this.body.properties.listeners[0].properties.sslProfile.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/sslProfiles/SslProfile",
      azapi_resource.this.body.properties.loadDistributionPolicies[0].properties.loadDistributionTargets[0].properties.backendAddressPool.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendAddressPools/BackendPool",
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/urlPathMaps/PathMap/pathRules/PathRule",
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.requestRoutingRules[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/requestRoutingRules/RouteRule",
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.targetListener.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/httpListeners/HttpListener",
      azapi_resource.this.body.properties.redirectConfigurations[0].properties.urlPathMaps[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/urlPathMaps/PathMap",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendAddressPool.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendAddressPools/BackendPool",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendHttpSettings.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendHttpSettingsCollection/BackendHttp",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.entraJWTValidationConfig.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/entraJWTValidationConfigs/EntraConfig",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.httpListener.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/httpListeners/HttpListener",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.loadDistributionPolicy.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/loadDistributionPolicies/LoadPolicy",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.redirectConfiguration.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/redirectConfigurations/Redirect",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.rewriteRuleSet.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/rewriteRuleSets/RewriteSet",
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.urlPathMap.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/urlPathMaps/PathMap",
      azapi_resource.this.body.properties.routingRules[0].properties.backendAddressPool.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendAddressPools/BackendPool",
      azapi_resource.this.body.properties.routingRules[0].properties.backendSettings.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendSettingsCollection/BackendSetting",
      azapi_resource.this.body.properties.routingRules[0].properties.listener.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/listeners/Listener",
      azapi_resource.this.body.properties.sslProfiles[0].properties.trustedClientCertificates[0].id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/trustedClientCertificates/ClientCert",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.defaultBackendAddressPool.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendAddressPools/BackendPool",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.defaultBackendHttpSettings.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendHttpSettingsCollection/BackendHttp",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.defaultLoadDistributionPolicy.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/loadDistributionPolicies/LoadPolicy",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.defaultRedirectConfiguration.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/redirectConfigurations/Redirect",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.defaultRewriteRuleSet.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/rewriteRuleSets/RewriteSet",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.backendAddressPool.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendAddressPools/BackendPool",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.backendHttpSettings.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/backendHttpSettingsCollection/BackendHttp",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.loadDistributionPolicy.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/loadDistributionPolicies/LoadPolicy",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.redirectConfiguration.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/redirectConfigurations/Redirect",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.rewriteRuleSet.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/applicationGateways/Gateway/rewriteRuleSets/RewriteSet",
    ])
    error_message = "Every internal reference family should resolve case-insensitively to the canonical declared child name."
  }

  assert {
    condition = alltrue([
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == "/opaque/public-ip",
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.subnet.id == "/opaque/frontend-subnet",
      azapi_resource.this.body.properties.httpListeners[0].properties.firewallPolicy.id == "/opaque/listener-policy",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.firewallPolicy.id == "/opaque/path-rule-policy",
      azapi_resource.this.body.properties.loadDistributionPolicies[0].properties.loadDistributionTargets[0].id == "/opaque/load-target-definition",
      azapi_resource.this.body.properties.privateLinkConfigurations[0].properties.ipConfigurations[0].id == "/opaque/private-link-ip-definition",
      azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].id == "/opaque/path-rule-definition",
    ])
    error_message = "External references and raw child definition IDs must remain unchanged."
  }

  assert {
    condition = alltrue([
      length(keys(azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules[0])) == 1,
      length(keys(azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendAddressPool)) == 1,
      length(keys(azapi_resource.this.body.properties.httpListeners[0].properties.frontendPort)) == 1,
      !contains(keys(azapi_resource.this.body.properties.requestRoutingRules[0].properties.backendAddressPool), "backend_address_pool_key"),
    ])
    error_message = "Reference helper fields must not be sent in the ARM body."
  }
}
