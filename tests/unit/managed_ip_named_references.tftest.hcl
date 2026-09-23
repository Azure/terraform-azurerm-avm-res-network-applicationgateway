mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      output = {
        fqdn       = null
        ip_address = "203.0.113.10"
      }
    }
  }
}
mock_provider "azurerm" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "eastus2"
  name             = "agw-combined"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-combined"
  public_ip_addresses = {
    edge = { name = "pip-combined" }
  }
  frontend_ip_configurations = [{
    name                  = "PublicFrontend"
    public_ip_address_key = "edge"
  }]
  frontend_ports = [{
    name       = "HttpPort"
    properties = { port = 80 }
  }]
  http_listeners = [{
    name = "HttpListener"
    properties = {
      frontend_ip_configuration = { name = "publicfrontend" }
      frontend_port             = { name = "httpport" }
      protocol                  = "Http"
    }
  }]
}

run "named_listener_resolves_a_managed_ip_frontend" {
  command = apply

  assert {
    condition = (
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["edge"].id &&
      azapi_resource.this.body.properties.httpListeners[0].properties.frontendIPConfiguration.id == "${var.parent_id}/providers/Microsoft.Network/applicationGateways/${var.name}/frontendIPConfigurations/PublicFrontend" &&
      azapi_resource.this.body.properties.httpListeners[0].properties.frontendPort.id == "${var.parent_id}/providers/Microsoft.Network/applicationGateways/${var.name}/frontendPorts/HttpPort"
    )
    error_message = "A named listener must resolve the frontend's child ID while the frontend retains its separately managed public IP ID."
  }

  assert {
    condition = (
      output.public_ip_addresses["edge"].resource_id == azapi_resource.public_ip_addresses["edge"].id &&
      length(keys(azapi_resource.this.body.properties.httpListeners[0].properties.frontendIPConfiguration)) == 1 &&
      !contains(keys(azapi_resource.this.body.properties.frontendIPConfigurations[0]), "public_ip_address_key")
    )
    error_message = "Managed IP outputs must be preserved and reference helper fields must not leak into the ARM body."
  }
}

run "named_private_link_and_managed_ip_share_a_frontend" {
  command = apply

  variables {
    private_link_configurations = [{
      name = "FrontendLink"
    }]
    frontend_ip_configurations = [{
      name                  = "PublicFrontend"
      public_ip_address_key = "edge"
      properties = {
        private_link_configuration = { name = "frontendlink" }
      }
    }]
  }

  assert {
    condition = (
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.publicIPAddress.id == azapi_resource.public_ip_addresses["edge"].id &&
      azapi_resource.this.body.properties.frontendIPConfigurations[0].properties.privateLinkConfiguration.id == "${var.parent_id}/providers/Microsoft.Network/applicationGateways/${var.name}/privateLinkConfigurations/FrontendLink" &&
      azapi_resource.this.body.properties.httpListeners[0].properties.frontendIPConfiguration.id == "${var.parent_id}/providers/Microsoft.Network/applicationGateways/${var.name}/frontendIPConfigurations/PublicFrontend"
    )
    error_message = "Managed public IP normalization must preserve named Private Link references on the same frontend."
  }
}
