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

resource "random_pet" "gateway" {
  length = 2
}

resource "terraform_data" "parent" {
  input = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
}

module "sut" {
  source = "../../../.."

  enable_telemetry = false
  frontend_ports = [{
    name = "port-${random_pet.gateway.id}"
  }]
  http_listeners = [{
    name = "listener"
    properties = {
      frontend_port = { name = "port-${random_pet.gateway.id}" }
    }
  }]
  location  = "westus2"
  name      = random_pet.gateway.id
  parent_id = terraform_data.parent.output
}
