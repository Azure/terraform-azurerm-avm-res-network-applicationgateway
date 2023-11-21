# Azure Application Gateway Terraform Module

Azure Application Gateway is a load balancer that enables you to manage and optimize the traffic to your web applications. When using Terraform to deploy Azure resources, you can make use of a Terraform module to define and configure the Azure Application Gateway. Here is a summary page about using an Azure Application Gateway Terraform module:

## What is Azure Application Gateway?
Azure Application Gateway is a Layer-7 load balancer service provided by Microsoft Azure. It enables you to manage traffic to your web applications by providing features like SSL termination, routing, and session affinity. Using Terraform, you can automate the provisioning and configuration of an Azure Application Gateway.

## Terraform Module for Azure Application Gateway
A Terraform module is a reusable and shareable configuration for defining and deploying Azure resources. To create an Azure Application Gateway using Terraform, you can use a pre-built module. This module simplifies the configuration process and allows you to create and manage an Application Gateway efficiently.


The terraform module supports following scenarios. 

## Supported frontend IP configuration
For current general availability support, Application Gateway V2 supports the following combinations
- Private IP and Public IP
- Public IP only

## Supported Scenarios 

The Terraform module for Azure Application Gateway is versatile and adaptable, accommodating various deployment scenarios. These scenarios dictate distinct input requirements. Here's an overview of the supported scenarios, each offering a unique configuration:

Each of these scenarios has its own set of input requirements, which can be tailored to meet your specific use case. The module provides the flexibility to deploy Azure Application Gateways for a wide range of applications and security needs.

**[Simple HTTP Application Gateway](examples/simple_http_app_gateway/README.md)** 
This scenario sets up a straightforward HTTP Application Gateway, typically for basic web applications or services.

**[Web Application Firewall (WAF)](examples/simple_waf_http_app_gateway/README.md)** 
A Web Application Firewall is employed to enhance security by inspecting and filtering traffic. Configuration entails defining custom rules and policies to protect against common web application vulnerabilities.

**[Self-Signed SSL (HTTPS)](examples/simple_http_app_gateway/README.md)**
In this scenario, self-signed SSL certificates are utilized to secure traffic to HTTPS. You'll need to configure SSL certificates and redirection rules.

**[SSL with Azure Key Vault](examples/kv_selfssl_waf_https_app_gateway/README.md)**
For enhanced security, SSL certificates are managed using Azure Key Vault. This scenario involves setting up Key Vault and integrating it with the Application Gateway. Detailed configuration for Key Vault and SSL certificates is necessary.

Before running the script, make sure you have logged in to your Azure subscription using the Azure CLI or Azure PowerShell, so Terraform can authenticate and interact with your Azure account.

Please ensure that you have a clear plan and architecture for your Azure Application Gateway, as the Terraform script should align with your specific requirements and network design.


