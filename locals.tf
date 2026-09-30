locals {
  managed_identities = {
    system_assigned_user_assigned = var.managed_identities.system_assigned || length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
    system_assigned = var.managed_identities.system_assigned ? {
      this = {
        type = "SystemAssigned"
      }
    } : {}
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      this = {
        type                       = "UserAssigned"
        user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
      }
    } : {}
  }
  resource_body = {
    properties = {
      authenticationCertificates = var.authentication_certificates == null ? null : [for item in var.authentication_certificates : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          data = item.properties.data
        }
      }]
      autoscaleConfiguration = var.autoscale_configuration == null ? null : {
        maxCapacity = var.autoscale_configuration.max_capacity
        minCapacity = var.autoscale_configuration.min_capacity
      }
      backendAddressPools = var.backend_address_pools == null ? null : [for item in var.backend_address_pools : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          backendAddresses = item.properties.backend_addresses == null ? null : [for item in item.properties.backend_addresses : item == null ? null : {
            fqdn      = item.fqdn
            ipAddress = item.ip_address
          }]
        }
      }]
      backendHttpSettingsCollection = var.backend_http_settings_collection == null ? null : [for settings_index, item in var.backend_http_settings_collection : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          affinityCookieName = item.properties.affinity_cookie_name
          authenticationCertificates = item.properties.authentication_certificates == null ? null : [
            for certificate_index, _ in item.properties.authentication_certificates :
            local.resolved_child_references["backend_http_settings_collection[${settings_index}].properties.authentication_certificates[${certificate_index}]"]
          ]
          connectionDraining = item.properties.connection_draining == null ? null : {
            drainTimeoutInSec = item.properties.connection_draining.drain_timeout_in_sec
            enabled           = item.properties.connection_draining.enabled
          }
          cookieBasedAffinity            = item.properties.cookie_based_affinity
          dedicatedBackendConnection     = item.properties.dedicated_backend_connection
          hostName                       = item.properties.host_name
          path                           = item.properties.path
          pickHostNameFromBackendAddress = item.properties.pick_host_name_from_backend_address
          port                           = item.properties.port
          probe                          = local.resolved_child_references["backend_http_settings_collection[${settings_index}].properties.probe"]
          probeEnabled                   = item.properties.probe_enabled
          protocol                       = item.properties.protocol
          requestTimeout                 = item.properties.request_timeout
          sniName                        = item.properties.sni_name
          trustedRootCertificates = item.properties.trusted_root_certificates == null ? null : [
            for certificate_index, _ in item.properties.trusted_root_certificates :
            local.resolved_child_references["backend_http_settings_collection[${settings_index}].properties.trusted_root_certificates[${certificate_index}]"]
          ]
          validateCertChainAndExpiry = item.properties.validate_cert_chain_and_expiry
          validateSNI                = item.properties.validate_sni
        }
      }]
      backendSettingsCollection = var.backend_settings_collection == null ? null : [for settings_index, item in var.backend_settings_collection : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          enableL4ClientIpPreservation   = item.properties.enable_l4_client_ip_preservation
          hostName                       = item.properties.host_name
          pickHostNameFromBackendAddress = item.properties.pick_host_name_from_backend_address
          port                           = item.properties.port
          probe                          = local.resolved_child_references["backend_settings_collection[${settings_index}].properties.probe"]
          protocol                       = item.properties.protocol
          timeout                        = item.properties.timeout
          trustedRootCertificates = item.properties.trusted_root_certificates == null ? null : [
            for certificate_index, _ in item.properties.trusted_root_certificates :
            local.resolved_child_references["backend_settings_collection[${settings_index}].properties.trusted_root_certificates[${certificate_index}]"]
          ]
        }
      }]
      customErrorConfigurations = var.custom_error_configurations == null ? null : [for item in var.custom_error_configurations : item == null ? null : {
        customErrorPageUrl = item.custom_error_page_url
        statusCode         = item.status_code
      }]
      enableFips  = var.enable_fips
      enableHttp2 = var.enable_http2
      entraJWTValidationConfigs = var.entra_jwt_validation_configs == null ? null : [for item in var.entra_jwt_validation_configs : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          audiences                 = item.properties.audiences == null ? null : [for item in item.properties.audiences : item]
          clientId                  = item.properties.client_id
          tenantId                  = item.properties.tenant_id
          unAuthorizedRequestAction = item.properties.un_authorized_request_action
        }
      }]
      firewallPolicy = var.firewall_policy == null ? null : {
        id = var.firewall_policy.id
      }
      forceFirewallPolicyAssociation = var.force_firewall_policy_association
      frontendIPConfigurations = local.frontend_ip_configurations == null ? null : [for frontend_index, item in local.frontend_ip_configurations : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          privateIPAddress          = item.properties.private_ip_address
          privateIPAllocationMethod = item.properties.private_ip_allocation_method
          privateLinkConfiguration  = local.resolved_child_references["frontend_ip_configurations[${frontend_index}].properties.private_link_configuration"]
          publicIPAddress = item.properties.public_ip_address == null ? null : {
            id = item.properties.public_ip_address.id
          }
          subnet = item.properties.subnet == null ? null : {
            id = item.properties.subnet.id
          }
        }
      }]
      frontendPorts = var.frontend_ports == null ? null : [for item in var.frontend_ports : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          port = item.properties.port
        }
      }]
      gatewayIPConfigurations = var.gateway_ip_configurations == null ? null : [for item in var.gateway_ip_configurations : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          subnet = item.properties.subnet == null ? null : {
            id = item.properties.subnet.id
          }
        }
      }]
      globalConfiguration = var.global_configuration == null ? null : {
        enableRequestBuffering  = var.global_configuration.enable_request_buffering
        enableResponseBuffering = var.global_configuration.enable_response_buffering
      }
      httpListeners = var.http_listeners == null ? null : [for listener_index, item in var.http_listeners : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          customErrorConfigurations = item.properties.custom_error_configurations == null ? null : [for item in item.properties.custom_error_configurations : item == null ? null : {
            customErrorPageUrl = item.custom_error_page_url
            statusCode         = item.status_code
          }]
          firewallPolicy = item.properties.firewall_policy == null ? null : {
            id = item.properties.firewall_policy.id
          }
          frontendIPConfiguration     = local.resolved_child_references["http_listeners[${listener_index}].properties.frontend_ip_configuration"]
          frontendPort                = local.resolved_child_references["http_listeners[${listener_index}].properties.frontend_port"]
          hostName                    = item.properties.host_name
          hostNames                   = item.properties.host_names == null ? null : [for item in item.properties.host_names : item]
          protocol                    = item.properties.protocol
          requireServerNameIndication = item.properties.require_server_name_indication
          sslCertificate              = local.resolved_child_references["http_listeners[${listener_index}].properties.ssl_certificate"]
          sslProfile                  = local.resolved_child_references["http_listeners[${listener_index}].properties.ssl_profile"]
        }
      }]
      listeners = var.listeners == null ? null : [for listener_index, item in var.listeners : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          frontendIPConfiguration = local.resolved_child_references["listeners[${listener_index}].properties.frontend_ip_configuration"]
          frontendPort            = local.resolved_child_references["listeners[${listener_index}].properties.frontend_port"]
          hostNames               = item.properties.host_names == null ? null : [for item in item.properties.host_names : item]
          protocol                = item.properties.protocol
          sslCertificate          = local.resolved_child_references["listeners[${listener_index}].properties.ssl_certificate"]
          sslProfile              = local.resolved_child_references["listeners[${listener_index}].properties.ssl_profile"]
        }
      }]
      loadDistributionPolicies = var.load_distribution_policies == null ? null : [for policy_index, item in var.load_distribution_policies : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          loadDistributionAlgorithm = item.properties.load_distribution_algorithm
          loadDistributionTargets = item.properties.load_distribution_targets == null ? null : [for target_index, item in item.properties.load_distribution_targets : item == null ? null : {
            id   = item.id
            name = item.name
            properties = item.properties == null ? null : {
              backendAddressPool = local.resolved_child_references["load_distribution_policies[${policy_index}].properties.load_distribution_targets[${target_index}].properties.backend_address_pool"]
              weightPerServer    = item.properties.weight_per_server
            }
          }]
        }
      }]
      privateLinkConfigurations = var.private_link_configurations == null ? null : [for item in var.private_link_configurations : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          ipConfigurations = item.properties.ip_configurations == null ? null : [for item in item.properties.ip_configurations : item == null ? null : {
            id   = item.id
            name = item.name
            properties = item.properties == null ? null : {
              primary                   = item.properties.primary
              privateIPAddress          = item.properties.private_ip_address
              privateIPAllocationMethod = item.properties.private_ip_allocation_method
              subnet = item.properties.subnet == null ? null : {
                id = item.properties.subnet.id
              }
            }
          }]
        }
      }]
      probes = var.probes == null ? null : [for item in var.probes : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          enableProbeProxyProtocolHeader = item.properties.enable_probe_proxy_protocol_header
          host                           = item.properties.host
          interval                       = item.properties.interval
          match = item.properties.match == null ? null : {
            body        = item.properties.match.body
            statusCodes = item.properties.match.status_codes == null ? null : [for item in item.properties.match.status_codes : item]
          }
          minServers                          = item.properties.min_servers
          path                                = item.properties.path
          pickHostNameFromBackendHttpSettings = item.properties.pick_host_name_from_backend_http_settings
          pickHostNameFromBackendSettings     = item.properties.pick_host_name_from_backend_settings
          port                                = item.properties.port
          protocol                            = item.properties.protocol
          timeout                             = item.properties.timeout
          unhealthyThreshold                  = item.properties.unhealthy_threshold
        }
      }]
      redirectConfigurations = var.redirect_configurations == null ? null : [for redirect_index, item in var.redirect_configurations : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          includePath        = item.properties.include_path
          includeQueryString = item.properties.include_query_string
          pathRules = item.properties.path_rules == null ? null : [
            for reference_index, _ in item.properties.path_rules :
            local.resolved_child_references["redirect_configurations[${redirect_index}].properties.path_rules[${reference_index}]"]
          ]
          redirectType = item.properties.redirect_type
          requestRoutingRules = item.properties.request_routing_rules == null ? null : [
            for reference_index, _ in item.properties.request_routing_rules :
            local.resolved_child_references["redirect_configurations[${redirect_index}].properties.request_routing_rules[${reference_index}]"]
          ]
          targetListener = local.resolved_child_references["redirect_configurations[${redirect_index}].properties.target_listener"]
          targetUrl      = item.properties.target_url
          urlPathMaps = item.properties.url_path_maps == null ? null : [
            for reference_index, _ in item.properties.url_path_maps :
            local.resolved_child_references["redirect_configurations[${redirect_index}].properties.url_path_maps[${reference_index}]"]
          ]
        }
      }]
      requestRoutingRules = var.request_routing_rules == null ? null : [for rule_index, item in var.request_routing_rules : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          backendAddressPool       = local.resolved_child_references["request_routing_rules[${rule_index}].properties.backend_address_pool"]
          backendHttpSettings      = local.resolved_child_references["request_routing_rules[${rule_index}].properties.backend_http_settings"]
          entraJWTValidationConfig = local.resolved_child_references["request_routing_rules[${rule_index}].properties.entra_jwt_validation_config"]
          httpListener             = local.resolved_child_references["request_routing_rules[${rule_index}].properties.http_listener"]
          loadDistributionPolicy   = local.resolved_child_references["request_routing_rules[${rule_index}].properties.load_distribution_policy"]
          priority                 = item.properties.priority
          redirectConfiguration    = local.resolved_child_references["request_routing_rules[${rule_index}].properties.redirect_configuration"]
          rewriteRuleSet           = local.resolved_child_references["request_routing_rules[${rule_index}].properties.rewrite_rule_set"]
          ruleType                 = item.properties.rule_type
          urlPathMap               = local.resolved_child_references["request_routing_rules[${rule_index}].properties.url_path_map"]
        }
      }]
      rewriteRuleSets = var.rewrite_rule_sets == null ? null : [for item in var.rewrite_rule_sets : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          rewriteRules = item.properties.rewrite_rules == null ? null : [for item in item.properties.rewrite_rules : item == null ? null : {
            actionSet = item.action_set == null ? null : {
              requestHeaderConfigurations = item.action_set.request_header_configurations == null ? null : [for item in item.action_set.request_header_configurations : item == null ? null : {
                headerName  = item.header_name
                headerValue = item.header_value
                headerValueMatcher = item.header_value_matcher == null ? null : {
                  ignoreCase = item.header_value_matcher.ignore_case
                  negate     = item.header_value_matcher.negate
                  pattern    = item.header_value_matcher.pattern
                }
              }]
              responseHeaderConfigurations = item.action_set.response_header_configurations == null ? null : [for item in item.action_set.response_header_configurations : item == null ? null : {
                headerName  = item.header_name
                headerValue = item.header_value
                headerValueMatcher = item.header_value_matcher == null ? null : {
                  ignoreCase = item.header_value_matcher.ignore_case
                  negate     = item.header_value_matcher.negate
                  pattern    = item.header_value_matcher.pattern
                }
              }]
              urlConfiguration = item.action_set.url_configuration == null ? null : {
                modifiedPath        = item.action_set.url_configuration.modified_path
                modifiedQueryString = item.action_set.url_configuration.modified_query_string
                reroute             = item.action_set.url_configuration.reroute
              }
            }
            conditions = item.conditions == null ? null : [for item in item.conditions : item == null ? null : {
              ignoreCase = item.ignore_case
              negate     = item.negate
              pattern    = item.pattern
              variable   = item.variable
            }]
            name         = item.name
            ruleSequence = item.rule_sequence
          }]
        }
      }]
      routingRules = var.routing_rules == null ? null : [for rule_index, item in var.routing_rules : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          backendAddressPool = local.resolved_child_references["routing_rules[${rule_index}].properties.backend_address_pool"]
          backendSettings    = local.resolved_child_references["routing_rules[${rule_index}].properties.backend_settings"]
          listener           = local.resolved_child_references["routing_rules[${rule_index}].properties.listener"]
          priority           = item.properties.priority
          ruleType           = item.properties.rule_type
        }
      }]
      sku = var.sku == null ? null : {
        capacity = var.sku.capacity
        family   = var.sku.family
        name     = var.sku.name
        tier     = var.sku.tier
      }
      sslCertificates = var.ssl_certificates == null ? null : [for item in var.ssl_certificates : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          data             = item.properties.data
          keyVaultSecretId = item.properties.key_vault_secret_id
          password         = item.properties.password
        }
      }]
      sslPolicy = var.ssl_policy == null ? null : {
        cipherSuites         = var.ssl_policy.policy_type == "Predefined" ? null : (var.ssl_policy.cipher_suites == null ? null : [for item in var.ssl_policy.cipher_suites : item])
        disabledSslProtocols = var.ssl_policy.policy_type == "Predefined" ? null : (var.ssl_policy.disabled_ssl_protocols == null ? null : [for item in var.ssl_policy.disabled_ssl_protocols : item])
        minProtocolVersion   = var.ssl_policy.policy_type == "Predefined" ? null : var.ssl_policy.min_protocol_version
        policyName           = var.ssl_policy.policy_name
        policyType           = var.ssl_policy.policy_type
      }
      sslProfiles = var.ssl_profiles == null ? null : [for profile_index, item in var.ssl_profiles : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          clientAuthConfiguration = item.properties.client_auth_configuration == null ? null : {
            verifyClientAuthMode     = item.properties.client_auth_configuration.verify_client_auth_mode
            verifyClientCertIssuerDN = item.properties.client_auth_configuration.verify_client_cert_issuer_dn
            verifyClientRevocation   = item.properties.client_auth_configuration.verify_client_revocation
          }
          sslPolicy = item.properties.ssl_policy == null ? null : {
            cipherSuites         = item.properties.ssl_policy.policy_type == "Predefined" ? null : (item.properties.ssl_policy.cipher_suites == null ? null : [for s in item.properties.ssl_policy.cipher_suites : s])
            disabledSslProtocols = item.properties.ssl_policy.policy_type == "Predefined" ? null : (item.properties.ssl_policy.disabled_ssl_protocols == null ? null : [for s in item.properties.ssl_policy.disabled_ssl_protocols : s])
            minProtocolVersion   = item.properties.ssl_policy.policy_type == "Predefined" ? null : item.properties.ssl_policy.min_protocol_version
            policyName           = item.properties.ssl_policy.policy_name
            policyType           = item.properties.ssl_policy.policy_type
          }
          trustedClientCertificates = item.properties.trusted_client_certificates == null ? null : [
            for certificate_index, _ in item.properties.trusted_client_certificates :
            local.resolved_child_references["ssl_profiles[${profile_index}].properties.trusted_client_certificates[${certificate_index}]"]
          ]
        }
      }]
      trustedClientCertificates = var.trusted_client_certificates == null ? null : [for item in var.trusted_client_certificates : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          data = item.properties.data
        }
      }]
      trustedRootCertificates = var.trusted_root_certificates == null ? null : [for item in var.trusted_root_certificates : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          data             = item.properties.data
          keyVaultSecretId = item.properties.key_vault_secret_id
        }
      }]
      urlPathMaps = var.url_path_maps == null ? null : [for map_index, item in var.url_path_maps : item == null ? null : {
        name = item.name
        properties = item.properties == null ? null : {
          defaultBackendAddressPool     = local.resolved_child_references["url_path_maps[${map_index}].properties.default_backend_address_pool"]
          defaultBackendHttpSettings    = local.resolved_child_references["url_path_maps[${map_index}].properties.default_backend_http_settings"]
          defaultLoadDistributionPolicy = local.resolved_child_references["url_path_maps[${map_index}].properties.default_load_distribution_policy"]
          defaultRedirectConfiguration  = local.resolved_child_references["url_path_maps[${map_index}].properties.default_redirect_configuration"]
          defaultRewriteRuleSet         = local.resolved_child_references["url_path_maps[${map_index}].properties.default_rewrite_rule_set"]
          pathRules = item.properties.path_rules == null ? null : [for rule_index, item in item.properties.path_rules : item == null ? null : {
            id   = item.id
            name = item.name
            properties = item.properties == null ? null : {
              backendAddressPool  = local.resolved_child_references["url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties.backend_address_pool"]
              backendHttpSettings = local.resolved_child_references["url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties.backend_http_settings"]
              firewallPolicy = item.properties.firewall_policy == null ? null : {
                id = item.properties.firewall_policy.id
              }
              loadDistributionPolicy = local.resolved_child_references["url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties.load_distribution_policy"]
              paths                  = item.properties.paths == null ? null : [for item in item.properties.paths : item]
              redirectConfiguration  = local.resolved_child_references["url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties.redirect_configuration"]
              rewriteRuleSet         = local.resolved_child_references["url_path_maps[${map_index}].properties.path_rules[${rule_index}].properties.rewrite_rule_set"]
            }
          }]
        }
      }]
      webApplicationFirewallConfiguration = var.web_application_firewall_configuration == null ? null : {
        disabledRuleGroups = var.web_application_firewall_configuration.disabled_rule_groups == null ? null : [for item in var.web_application_firewall_configuration.disabled_rule_groups : item == null ? null : {
          ruleGroupName = item.rule_group_name
          rules         = item.rules == null ? null : [for item in item.rules : item]
        }]
        enabled = var.web_application_firewall_configuration.enabled
        exclusions = var.web_application_firewall_configuration.exclusions == null ? null : [for item in var.web_application_firewall_configuration.exclusions : item == null ? null : {
          matchVariable         = item.match_variable
          selector              = item.selector
          selectorMatchOperator = item.selector_match_operator
        }]
        fileUploadLimitInMb    = var.web_application_firewall_configuration.file_upload_limit_in_mb
        firewallMode           = var.web_application_firewall_configuration.firewall_mode
        maxRequestBodySize     = var.web_application_firewall_configuration.max_request_body_size
        maxRequestBodySizeInKb = var.web_application_firewall_configuration.max_request_body_size_in_kb
        requestBodyCheck       = var.web_application_firewall_configuration.request_body_check
        ruleSetType            = var.web_application_firewall_configuration.rule_set_type
        ruleSetVersion         = var.web_application_firewall_configuration.rule_set_version
      }
    }
    zones = var.zones == null ? null : [for item in var.zones : item]
  }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
