mock_provider "azapi" {}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "westus2"
  name             = "gateway"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
}

run "renders_flat_fields_into_arm_properties" {
  command = apply

  variables {
    authentication_certificates = [{ name = "auth", data = "auth-data" }]
    backend_address_pools = [{
      name = "pool"
      backend_addresses = [
        { fqdn = "backend.example.com" },
        { ip_address = "10.0.0.4" },
      ]
    }]
    backend_http_settings_collection = [{
      affinity_cookie_name        = "affinity"
      authentication_certificates = [{ id = "/opaque/auth" }]
      connection_draining = {
        drain_timeout_in_sec = 0
        enabled              = false
      }
      cookie_based_affinity               = "Disabled"
      dedicated_backend_connection        = false
      host_name                           = "backend.example.com"
      name                                = "http"
      path                                = "/"
      pick_host_name_from_backend_address = false
      port                                = 0
      probe                               = { id = "/opaque/probe" }
      probe_enabled                       = false
      protocol                            = "Http"
      request_timeout                     = 0
      sni_name                            = "sni.example.com"
      trusted_root_certificates           = [{ id = "/opaque/root" }]
      validate_cert_chain_and_expiry      = false
      validate_sni                        = false
    }]
    backend_settings_collection = [{
      enable_l4_client_ip_preservation    = false
      host_name                           = "tcp.example.com"
      name                                = "tcp"
      pick_host_name_from_backend_address = false
      port                                = 0
      probe                               = { id = "/opaque/tcp-probe" }
      protocol                            = "Tcp"
      timeout                             = 0
      trusted_root_certificates           = []
    }]
    entra_jwt_validation_configs = [{
      audiences                    = []
      client_id                    = "client"
      name                         = "jwt"
      tenant_id                    = "tenant"
      un_authorized_request_action = "Return401"
    }]
    frontend_ip_configurations = [{
      name                         = "frontend"
      private_ip_address           = "10.0.0.10"
      private_ip_allocation_method = "Static"
      private_link_configuration   = { id = "/opaque/private-link" }
      public_ip_address            = { id = "/opaque/public-ip" }
      subnet                       = { id = "/opaque/frontend-subnet" }
    }]
    frontend_ports = [{ name = "port", port = 0 }]
    gateway_ip_configurations = [{
      name   = "gateway-ip"
      subnet = { id = "/opaque/gateway-subnet" }
    }]
    http_listeners = [{
      custom_error_configurations    = []
      firewall_policy                = { id = "/opaque/listener-policy" }
      frontend_ip_configuration      = { id = "/opaque/frontend" }
      frontend_port                  = { id = "/opaque/port" }
      host_name                      = "listener.example.com"
      host_names                     = []
      name                           = "http-listener"
      protocol                       = "Https"
      require_server_name_indication = false
      ssl_certificate                = { id = "/opaque/certificate" }
      ssl_profile                    = { id = "/opaque/profile" }
    }]
    listeners = [{
      frontend_ip_configuration = { id = "/opaque/frontend" }
      frontend_port             = { id = "/opaque/port" }
      host_names                = []
      name                      = "listener"
      protocol                  = "Tls"
      ssl_certificate           = { id = "/opaque/certificate" }
      ssl_profile               = { id = "/opaque/profile" }
    }]
    load_distribution_policies = [{
      load_distribution_algorithm = "RoundRobin"
      name                        = "distribution"
      load_distribution_targets = [{
        backend_address_pool = { id = "/opaque/pool" }
        id                   = "/opaque/target"
        name                 = "target"
        weight_per_server    = 0
      }]
    }]
    private_link_configurations = [{
      name = "private-link"
      ip_configurations = [{
        id                           = "/opaque/private-ip"
        name                         = "private-ip"
        primary                      = false
        private_ip_address           = "10.0.0.5"
        private_ip_allocation_method = "Static"
        subnet                       = { id = "/opaque/private-subnet" }
      }]
    }]
    probes = [{
      enable_probe_proxy_protocol_header = false
      host                               = "probe.example.com"
      interval                           = 0
      match = {
        body         = ""
        status_codes = []
      }
      min_servers                               = 0
      name                                      = "probe"
      path                                      = "/health"
      pick_host_name_from_backend_http_settings = false
      pick_host_name_from_backend_settings      = false
      port                                      = 0
      protocol                                  = "Http"
      timeout                                   = 0
      unhealthy_threshold                       = 0
    }]
    redirect_configurations = [{
      include_path          = false
      include_query_string  = false
      name                  = "redirect"
      path_rules            = []
      redirect_type         = "Permanent"
      request_routing_rules = []
      target_listener       = { id = "/opaque/listener" }
      target_url            = "https://example.com"
      url_path_maps         = []
    }]
    request_routing_rules = [{
      backend_address_pool        = { id = "/opaque/pool" }
      backend_http_settings       = { id = "/opaque/http" }
      entra_jwt_validation_config = { id = "/opaque/jwt" }
      http_listener               = { id = "/opaque/http-listener" }
      load_distribution_policy    = { id = "/opaque/distribution" }
      name                        = "request-rule"
      priority                    = 0
      redirect_configuration      = { id = "/opaque/redirect" }
      rewrite_rule_set            = { id = "/opaque/rewrite" }
      rule_type                   = "Basic"
      url_path_map                = { id = "/opaque/map" }
    }]
    rewrite_rule_sets = [{
      name = "rewrite"
      rewrite_rules = [{
        action_set = {
          request_header_configurations = [{
            header_name  = "x-request"
            header_value = ""
            header_value_matcher = {
              ignore_case = false
              negate      = false
              pattern     = ""
            }
          }]
          response_header_configurations = []
          url_configuration = {
            modified_path         = ""
            modified_query_string = ""
            reroute               = false
          }
        }
        conditions    = []
        name          = "rule"
        rule_sequence = 0
      }]
    }]
    routing_rules = [{
      backend_address_pool = { id = "/opaque/pool" }
      backend_settings     = { id = "/opaque/tcp" }
      listener             = { id = "/opaque/listener" }
      name                 = "routing-rule"
      priority             = 0
      rule_type            = "Basic"
    }]
    ssl_certificates = [{
      data                = "certificate-data"
      key_vault_secret_id = "https://example.vault.azure.net/secrets/certificate"
      name                = "certificate"
      password            = ""
    }]
    ssl_profiles = [{
      client_auth_configuration = {
        verify_client_auth_mode      = "Optional"
        verify_client_cert_issuer_dn = false
        verify_client_revocation     = "None"
      }
      name = "profile"
      ssl_policy = {
        cipher_suites          = []
        disabled_ssl_protocols = []
        min_protocol_version   = "TLSv1_2"
        policy_name            = "custom"
        policy_type            = "Custom"
      }
      trusted_client_certificates = []
    }]
    trusted_client_certificates = [{ name = "client-certificate", data = "client-data" }]
    trusted_root_certificates = [{
      data                = "root-data"
      key_vault_secret_id = "https://example.vault.azure.net/secrets/root"
      name                = "root-certificate"
    }]
    url_path_maps = [{
      default_backend_address_pool     = { id = "/opaque/pool" }
      default_backend_http_settings    = { id = "/opaque/http" }
      default_load_distribution_policy = { id = "/opaque/distribution" }
      default_redirect_configuration   = { id = "/opaque/redirect" }
      default_rewrite_rule_set         = { id = "/opaque/rewrite" }
      name                             = "map"
      path_rules = [{
        backend_address_pool     = { id = "/opaque/pool" }
        backend_http_settings    = { id = "/opaque/http" }
        firewall_policy          = { id = "/opaque/path-policy" }
        id                       = "/opaque/path-rule"
        load_distribution_policy = { id = "/opaque/distribution" }
        name                     = "path-rule"
        paths                    = []
        redirect_configuration   = { id = "/opaque/redirect" }
        rewrite_rule_set         = { id = "/opaque/rewrite" }
      }]
    }]
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.backendHttpSettingsCollection[0].properties) == jsonencode({
      affinityCookieName         = "affinity"
      authenticationCertificates = [{ id = "/opaque/auth" }]
      connectionDraining = {
        drainTimeoutInSec = 0
        enabled           = false
      }
      cookieBasedAffinity            = "Disabled"
      dedicatedBackendConnection     = false
      hostName                       = "backend.example.com"
      path                           = "/"
      pickHostNameFromBackendAddress = false
      port                           = 0
      probe                          = { id = "/opaque/probe" }
      probeEnabled                   = false
      protocol                       = "Http"
      requestTimeout                 = 0
      sniName                        = "sni.example.com"
      trustedRootCertificates        = [{ id = "/opaque/root" }]
      validateCertChainAndExpiry     = false
      validateSNI                    = false
    })
    error_message = "Every flat backend HTTP setting must render into the same complete ARM properties object."
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties.probes[0].properties) == jsonencode({
      enableProbeProxyProtocolHeader = false
      host                           = "probe.example.com"
      interval                       = 0
      match = {
        body        = ""
        statusCodes = []
      }
      minServers                          = 0
      path                                = "/health"
      pickHostNameFromBackendHttpSettings = false
      pickHostNameFromBackendSettings     = false
      port                                = 0
      protocol                            = "Http"
      timeout                             = 0
      unhealthyThreshold                  = 0
    })
    error_message = "False, zero, empty strings, and empty lists must survive flat probe rendering."
  }

  assert {
    condition = alltrue([
      azapi_resource.this.body.properties.loadDistributionPolicies[0].properties.loadDistributionTargets[0].properties.weightPerServer == 0,
      !azapi_resource.this.body.properties.privateLinkConfigurations[0].properties.ipConfigurations[0].properties.primary,
      length(azapi_resource.this.body.properties.redirectConfigurations[0].properties.pathRules) == 0,
      azapi_resource.this.body.properties.requestRoutingRules[0].properties.priority == 0,
      !azapi_resource.this.body.properties.rewriteRuleSets[0].properties.rewriteRules[0].actionSet.urlConfiguration.reroute,
      azapi_resource.this.body.properties.routingRules[0].properties.priority == 0,
      length(azapi_resource.this.body.properties.sslProfiles[0].properties.sslPolicy.cipherSuites) == 0,
      length(azapi_resource.this.body.properties.urlPathMaps[0].properties.pathRules[0].properties.paths) == 0,
      length(local.legacy_properties_wrapper_paths) == 0,
    ])
    error_message = "Flat top-level and nested definitions must preserve explicit false, zero, and empty collection values without leaking the sentinel."
  }
}
