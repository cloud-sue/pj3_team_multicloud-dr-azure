terraform {
  required_version = ">= 1.6.0"

  backend "azurerm" {
    resource_group_name  = "rg-azsis-kbeauty-blob"
    storage_account_name = "azsiskbeautytfstate"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate" # 환경별로 경로 구분
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.62"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.48"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    # Key Vault 인증서를 만들 때 삭제된 인증서 복구를 시도하지 말고 그냥 새로 생성해라
    key_vault {
      recover_soft_deleted_certificates = false
    }
  }
}

# Let's Encrypt 같은 ACME CA에서 공인 인증서를 발급받기 위한 provider입니다.
# 기본값은 운영 Let's Encrypt이며, 테스트할 때는 acme_server_url을 staging URL로 바꿉니다.
provider "acme" {
  server_url = var.acme_server_url
}

# AKS 생성 후 Helm chart를 설치하기 위한 provider입니다.
# External Secrets Operator처럼 클러스터 add-on 성격의 리소스를 Terraform에서 관리합니다.
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config_host
    client_certificate     = base64decode(module.aks.kube_config_client_certificate)
    client_key             = base64decode(module.aks.kube_config_client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config_cluster_ca_certificate)
  }
}

# External Secrets Operator의 ClusterSecretStore 같은 Kubernetes 리소스를 Terraform에서 관리합니다.
provider "kubernetes" {
  host                   = module.aks.kube_config_host
  client_certificate     = base64decode(module.aks.kube_config_client_certificate)
  client_key             = base64decode(module.aks.kube_config_client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config_cluster_ca_certificate)
}
