terraform {
  required_version = ">= 1.12, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.117, < 5.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

variable "location" {
  type    = string
  default = "eastus2"
}

resource "random_id" "name" {
  byte_length = 4
}

resource "azapi_resource" "resource_group" {
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  name                   = "rg-unknown-${random_id.name.hex}"
  parent_id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
  location               = var.location
  body                   = {}
  response_export_values = []
}

module "gateway" {
  source = "../../../.."

  enable_telemetry = false
  location         = var.location
  name             = "agw-${random_id.name.hex}"
  parent_id        = azapi_resource.resource_group.id
  public_ip_addresses = {
    edge = {
      name      = "pip-${random_id.name.hex}"
      parent_id = azapi_resource.resource_group.id
    }
  }
  frontend_ip_configurations = [{
    name                  = "public"
    public_ip_address_key = "edge"
  }]
  sku = {
    capacity = 1
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
}

output "public_ip_keys" {
  value = keys(module.gateway.public_ip_addresses)
}
