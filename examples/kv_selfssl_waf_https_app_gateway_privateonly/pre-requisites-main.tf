#---------- All Required Pre-requisites Section-----------

# Below code allow you to create Azure resource group for application gateway, 
# Virtual network, subnets, log analytics workspace, virtual machine scale set, 
# network security group, storage account, key vault and user assigned identity.

resource "azurerm_resource_group" "rg_group" {
  location = "southeastasia"
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.90.0.0/16"] # address space for VNET 
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

resource "azurerm_subnet" "frontend" {
  address_prefixes     = ["10.90.0.0/24"] #[local.subnet_range[0]]
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "backend" {
  address_prefixes     = ["10.90.1.0/24"]
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "nat_subnet" {
  address_prefixes     = ["10.90.6.0/24"]
  name                 = "nat_subnet"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Required for to deploy VMSS and Web Server to host application
resource "azurerm_subnet" "workload" {
  address_prefixes     = ["10.90.2.0/24"]
  name                 = "workload"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

# Required for Frontend Private IP endpoint testing 
resource "azurerm_subnet" "private_ip_test" {
  address_prefixes     = ["10.90.3.0/24"]
  name                 = "private_ip_test"
  resource_group_name  = azurerm_resource_group.rg_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  service_endpoints    = ["Microsoft.KeyVault"]
}

# Datasource-1: To get Azure Tenant Id
data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "appag_umid" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}


resource "azurerm_key_vault" "keyvault" {
  location                        = azurerm_resource_group.rg_group.location
  name                            = module.naming.key_vault.name_unique
  resource_group_name             = azurerm_resource_group.rg_group.name
  sku_name                        = "premium"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false
  soft_delete_retention_days      = 7
}

resource "azurerm_key_vault_access_policy" "key_vault_default_policy" {
  key_vault_id = azurerm_key_vault.keyvault.id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]
  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
  ]
  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_key_vault_access_policy" "appag_key_vault_access_policy" {
  key_vault_id = azurerm_key_vault.keyvault.id
  object_id    = azurerm_user_assigned_identity.appag_umid.principal_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  secret_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_certificate" "ssl_cert_id" {
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "app-gateway-cert"

  certificate {
    contents = filebase64("./ssl_cert_generate/certificate.pfx")
    password = "terraform-avm"
  }
  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }
    key_properties {
      exportable = true
      key_type   = "RSA"
      reuse_key  = true
      key_size   = 2048
    }
    secret_properties {
      content_type = "application/x-pkcs12"
    }
    lifetime_action {
      action {
        action_type = "EmailContacts"
      }
      trigger {
        days_before_expiry = 10
      }
    }
  }

  depends_on = [azurerm_key_vault_access_policy.key_vault_default_policy]
}


resource "azurerm_web_application_firewall_policy" "azure_waf" {
  location            = azurerm_resource_group.rg_group.location
  name                = "example-wafpolicy"
  resource_group_name = azurerm_resource_group.rg_group.name

  managed_rules {
    managed_rule_set {
      version = "3.2"
      type    = "OWASP"

      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"

        rule {
          id      = "920300"
          action  = "Log"
          enabled = true
        }
        rule {
          id      = "920440"
          action  = "Block"
          enabled = true
        }
      }
    }
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }
  }
  custom_rules {
    action    = "Block"
    priority  = 1
    rule_type = "MatchRule"
    name      = "Rule1"

    match_conditions {
      operator           = "IPMatch"
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
      negation_condition = false

      match_variables {
        variable_name = "RemoteAddr"
      }
    }
  }
  custom_rules {
    action    = "Block"
    priority  = 2
    rule_type = "MatchRule"
    name      = "Rule2"

    match_conditions {
      operator           = "IPMatch"
      match_values       = ["192.168.1.0/24"]
      negation_condition = false

      match_variables {
        variable_name = "RemoteAddr"
      }
    }
    match_conditions {
      operator           = "Contains"
      match_values       = ["Windows"]
      negation_condition = false

      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }
    }
  }
  policy_settings {
    enabled                     = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
    mode                        = "Prevention"
    request_body_check          = true
  }
}

resource "azurerm_private_endpoint" "example" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.private_endpoint.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
  subnet_id           = azurerm_subnet.backend.id

  private_service_connection {
    is_manual_connection           = false
    name                           = "example-connection"
    private_connection_resource_id = azurerm_key_vault.keyvault.id
    subresource_names              = ["vault"]
  }
}

#To enroll into the public preview for the enhanced Application Gateway network controls via Azure CLI,
resource "null_resource" "register_feature" {
  provisioner "local-exec" {
    command = <<EOT
      az feature register --namespace Microsoft.Network --name EnableApplicationGatewayNetworkIsolation
   
    EOT
  }
}