terraform {
  # OIDC bootstrap 코드는 Terraform 1.6 이상에서 동작하도록 고정한다.
  required_version = ">= 1.6.0"

  required_providers {
    # Azure Entra ID의 App Registration, Service Principal, Federated Credential을 만든다.
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }

    # Azure 구독에 RBAC Role Assignment를 만들 때 사용한다.
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }
  }
}

# 지정한 tenant를 기준으로 Entra ID 리소스를 생성한다.
provider "azuread" {
  tenant_id = local.tenant_id
}

# GitHub Actions가 접근할 Azure 구독에 RBAC 권한을 부여하기 위한 provider다.
provider "azurerm" {
  subscription_id = local.subscription_id
  tenant_id       = local.tenant_id

  features {}
}
