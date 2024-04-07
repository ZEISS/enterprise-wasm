terraform {
  required_version = "~>1.6.6"
   required_providers {
    azurerm = {
      source = "registry.terraform.io/hashicorp/azurerm"
    }
    azapi = {
      source  = "registry.terraform.io/Azure/azapi"
    }
    kubernetes = {
      source = "registry.terraform.io/hashicorp/kubernetes"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
    helm = {
      source = "registry.terraform.io/hashicorp/helm"
    }
    random = {
      source = "registry.terraform.io/hashicorp/random"
    }
  }
}
