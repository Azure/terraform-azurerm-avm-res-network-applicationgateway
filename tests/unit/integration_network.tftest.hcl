mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/applicationGateways/agw-unit"
      output = {
        fqdn       = "avm-pip.example.test"
        ip_address = "203.0.113.10"
      }
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      output = {
        fqdn               = "avm-pip.example.test"
        ip_address         = "203.0.113.10"
        provisioning_state = "Succeeded"
        frontend_ip_configurations = [{
          name = "public"
          properties = {
            publicIPAddress = {
              id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/publicIPAddresses/pip-unit"
            }
          }
        }]
      }
    }
  }
}

mock_provider "azurerm" {}
mock_provider "random" {}

run "integration_subnet_has_application_gateway_nsg" {
  command = apply

  module {
    source = "./tests/integration/fixtures/public_ip_addresses"
  }

  override_resource {
    target = azapi_resource.resource_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit"
    }
  }

  override_resource {
    target = azapi_resource.virtual_network
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit"
    }
  }

  override_resource {
    target = azapi_resource.subnet
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/virtualNetworks/vnet-unit/subnets/application-gateway"
    }
  }

  override_resource {
    target = azapi_resource.network_security_group
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/networkSecurityGroups/nsg-unit"
    }
  }

  override_resource {
    target = module.gateway.azapi_resource.public_ip_addresses["edge"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/publicIPAddresses/pip-unit"
    }
  }

  assert {
    condition = (
      azapi_resource.subnet.body.properties.networkSecurityGroup.id == azapi_resource.network_security_group.id &&
      azapi_resource.network_security_group.parent_id == azapi_resource.resource_group.id &&
      azapi_resource.network_security_group.location == var.location &&
      azapi_resource.network_security_group.type == "Microsoft.Network/networkSecurityGroups@2025-03-01"
    )
    error_message = "The integration subnet must include its NSG in the initial create request, in the fixture's resource group and region."
  }

  assert {
    condition = anytrue([
      for rule in azapi_resource.network_security_group.body.properties.securityRules :
      rule.properties.access == "Allow" &&
      rule.properties.direction == "Inbound" &&
      rule.properties.protocol == "Tcp" &&
      rule.properties.sourceAddressPrefix == "Internet" &&
      rule.properties.sourcePortRange == "*" &&
      rule.properties.destinationAddressPrefix == azapi_resource.subnet.body.properties.addressPrefix &&
      rule.properties.destinationPortRange == "80"
    ])
    error_message = "The integration NSG must allow HTTP client traffic to the Application Gateway subnet."
  }

  assert {
    condition = anytrue([
      for rule in azapi_resource.network_security_group.body.properties.securityRules :
      rule.properties.access == "Allow" &&
      rule.properties.direction == "Inbound" &&
      rule.properties.protocol == "Tcp" &&
      rule.properties.sourceAddressPrefix == "GatewayManager" &&
      rule.properties.sourcePortRange == "*" &&
      rule.properties.destinationAddressPrefix == "*" &&
      rule.properties.destinationPortRange == "65200-65535"
    ])
    error_message = "The integration NSG must allow Application Gateway v2 infrastructure traffic from GatewayManager."
  }

  assert {
    condition = (
      length(azapi_resource.network_security_group.body.properties.securityRules) == 2 &&
      length(toset([for rule in azapi_resource.network_security_group.body.properties.securityRules : rule.properties.priority])) == 2 &&
      alltrue([
        for rule in azapi_resource.network_security_group.body.properties.securityRules :
        rule.properties.access == "Allow" &&
        rule.properties.direction == "Inbound" &&
        rule.properties.priority >= 100 &&
        rule.properties.priority <= 4096
      ])
    )
    error_message = "The integration NSG must use distinct valid priorities without overriding default load-balancer probe or outbound access."
  }
}
