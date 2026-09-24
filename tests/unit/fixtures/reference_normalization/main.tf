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

resource "random_id" "reference" {
  byte_length = 4
}

module "sut" {
  source = "../../../.."

  enable_telemetry            = false
  location                    = "westus2"
  name                        = "gateway"
  parent_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
  authentication_certificates = [{ name = "KnownCertificate" }]
  probes                      = [{ name = "KnownProbe" }]
  backend_http_settings_collection = [{
    name = "settings"
    properties = {
      authentication_certificates = [{
        id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/external/providers/Microsoft.Network/probes/${random_id.reference.hex}"
      }]
      probe = { probe_key = "knownprobe" }
    }
  }]
}

output "gateway_name" {
  value = module.sut.name
}
