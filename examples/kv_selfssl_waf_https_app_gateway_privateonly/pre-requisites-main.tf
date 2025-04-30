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

# Deploy NAT Gateway
resource "azurerm_nat_gateway" "nat_gateway" {
  location                = azurerm_resource_group.rg_group.location
  name                    = module.naming.nat_gateway.name_unique
  resource_group_name     = azurerm_resource_group.rg_group.name
  idle_timeout_in_minutes = 10
  sku_name                = "Standard"
  #Only one zone can be specified for this resource.
  zones = ["1"]
}

# Create a Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway_public_ip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.public_ip.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
  sku                 = "Standard"
  #Public IP Prefix must have same zones. Standard SKU NAT Gateway
  zones = [1]
}

# Associate NAT Gateway with the nat_subnet
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_gateway_public_ip.id
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "nat_subnet_nsg" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

#Add an NSG Rule to Allow Outbound Internet Traffic

# Create a Network Security Group (NSG) for the Application Gateway Subnet
resource "azurerm_network_security_group" "private_ip_test_nsg" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.network_security_group.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

# Inbound Rule: Allow Azure Load Balancer Probes
resource "azurerm_network_security_rule" "allow_inbound_azure_load_balancer" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "AllowInboundAzureLoadBalancer"
  network_security_group_name = azurerm_network_security_group.private_ip_test_nsg.name
  priority                    = 100
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.rg_group.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  source_port_range           = "*"

  depends_on = [azurerm_network_security_group.private_ip_test_nsg]
}

# Inbound Rule: Allow Traffic from Trusted Sources
resource "azurerm_network_security_rule" "allow_inbound_trusted_sources" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "AllowInboundTrustedSources"
  network_security_group_name = azurerm_network_security_group.private_ip_test_nsg.name
  priority                    = 200
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.rg_group.name
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_public_ip.nat_gateway_public_ip.ip_address # Replace with your trusted IP range
  source_port_range           = "*"

  depends_on = [azurerm_network_security_rule.allow_inbound_azure_load_balancer]
}

# Outbound Rule: Allow Outbound Internet Traffic
resource "azurerm_network_security_rule" "allow_outbound_internet" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "AllowOutboundInternet"
  network_security_group_name = azurerm_network_security_group.private_ip_test_nsg.name
  priority                    = 300
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.rg_group.name
  destination_address_prefix  = "Internet"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"

  depends_on = [azurerm_network_security_rule.allow_inbound_trusted_sources]
}

# Outbound Rule: Allow Outbound Traffic to Azure Services
resource "azurerm_network_security_rule" "allow_outbound_azure_services" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "AllowOutboundAzureServices"
  network_security_group_name = azurerm_network_security_group.private_ip_test_nsg.name
  priority                    = 400
  protocol                    = "*"
  resource_group_name         = azurerm_resource_group.rg_group.name
  destination_address_prefix  = "AzureCloud"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  source_port_range           = "*"

  depends_on = [azurerm_network_security_rule.allow_outbound_internet]
}

# Associate the NSG with the Application Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "private_ip_test_nsg_association" {
  network_security_group_id = azurerm_network_security_group.private_ip_test_nsg.id
  subnet_id                 = azurerm_subnet.private_ip_test.id

  depends_on = [azurerm_network_security_rule.allow_outbound_azure_services]
}

# Create a Route Table
resource "azurerm_route_table" "nat_gateway_route_table" {
  location            = azurerm_resource_group.rg_group.location
  name                = module.naming.route_table.name_unique
  resource_group_name = azurerm_resource_group.rg_group.name
}

# Add a Route for Internet Traffic
resource "azurerm_route" "nat_gateway_route" {
  address_prefix         = "0.0.0.0/0"
  name                   = "InternetRoute"
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = azurerm_resource_group.rg_group.name
  route_table_name       = azurerm_route_table.nat_gateway_route_table.name
  next_hop_in_ip_address = "10.90.6.4"
}

# Associate Route Table with Application Gateway Subnet
resource "azurerm_subnet_route_table_association" "private_ip_test_route_table_association" {
  route_table_id = azurerm_route_table.nat_gateway_route_table.id
  subnet_id      = azurerm_subnet.private_ip_test.id
}