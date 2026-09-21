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
        authentication_certificates = [{ name = "authcert" }]
        probe                       = { name = "PROBE" }
        trusted_root_certificates   = [{ name = "rootcert" }]
      }
    }]
    backend_settings_collection = [{
      name = "BackendSetting"
      properties = {
        probe                     = { name = "probe" }
        trusted_root_certificates = [{ name = "ROOTCERT" }]
      }
    }]
    entra_jwt_validation_configs = [{ name = "EntraConfig" }]
    frontend_ip_configurations = [{
      name = "FrontendIp"
      properties = {
        private_link_configuration = { name = "privatelink" }
        public_ip_address          = { id = "/opaque/public-ip" }
        subnet                     = { id = "/opaque/frontend-subnet" }
      }
    }]
    frontend_ports = [{ name = "FrontendPort", properties = { port = 443 } }]
    http_listeners = [{
      name = "HttpListener"
      properties = {
        firewall_policy           = { id = "/opaque/listener-policy" }
        frontend_ip_configuration = { name = "frontendip" }
        frontend_port             = { name = "FRONTENDPORT" }
        ssl_certificate           = { name = "sslcert" }
        ssl_profile               = { name = "SSLPROFILE" }
      }
    }]
    listeners = [{
      name = "Listener"
      properties = {
        frontend_ip_configuration = { name = "FRONTENDIP" }
        frontend_port             = { name = "frontendport" }
        ssl_certificate           = { name = "SSLCERT" }
        ssl_profile               = { name = "sslprofile" }
      }
    }]
    load_distribution_policies = [{
      name = "LoadPolicy"
      properties = {
        load_distribution_targets = [{
          id   = "/opaque/load-target-definition"
          name = "LoadTarget"
          properties = {
            backend_address_pool = { name = "backendpool" }
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
        path_rules            = [{ name = "PATHRULE", url_path_map_name = "pathmap" }]
        request_routing_rules = [{ name = "ROUTERULE" }]
        target_listener       = { name = "httplistener" }
        url_path_maps         = [{ name = "PATHMAP" }]
      }
    }]
    request_routing_rules = [{
      name = "RouteRule"
      properties = {
        backend_address_pool        = { name = "BACKENDPOOL" }
        backend_http_settings       = { name = "backendhttp" }
        entra_jwt_validation_config = { name = "ENTRACONFIG" }
        http_listener               = { name = "HTTPListener" }
        load_distribution_policy    = { name = "loadpolicy" }
        redirect_configuration      = { name = "REDIRECT" }
        rewrite_rule_set            = { name = "rewriteset" }
        url_path_map                = { name = "pathmap" }
      }
    }]
    rewrite_rule_sets = [{ name = "RewriteSet" }]
    routing_rules = [{
      name = "RoutingRule"
      properties = {
        backend_address_pool = { name = "backendpool" }
        backend_settings     = { name = "BACKENDSETTING" }
        listener             = { name = "listener" }
        priority             = 1
      }
    }]
    ssl_certificates = [{ name = "SslCert" }]
    ssl_profiles = [{
      name = "SslProfile"
      properties = {
        trusted_client_certificates = [{ name = "clientcert" }]
      }
    }]
    trusted_client_certificates = [{ name = "ClientCert" }]
    trusted_root_certificates   = [{ name = "RootCert" }]
    url_path_maps = [{
      name = "PathMap"
      properties = {
        default_backend_address_pool     = { name = "backendpool" }
        default_backend_http_settings    = { name = "BACKENDHTTP" }
        default_load_distribution_policy = { name = "loadpolicy" }
        default_redirect_configuration   = { name = "redirect" }
        default_rewrite_rule_set         = { name = "REWRITESET" }
        path_rules = [{
          id   = "/opaque/path-rule-definition"
          name = "PathRule"
          properties = {
            backend_address_pool     = { name = "backendpool" }
            backend_http_settings    = { name = "backendhttp" }
            firewall_policy          = { id = "/opaque/path-rule-policy" }
            load_distribution_policy = { name = "loadpolicy" }
            redirect_configuration   = { name = "redirect" }
            rewrite_rule_set         = { name = "rewriteset" }
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
    ])
    error_message = "Reference helper fields must not be sent in the ARM body."
  }
}
