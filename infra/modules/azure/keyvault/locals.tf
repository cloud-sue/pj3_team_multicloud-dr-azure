locals {
  # Key Vault의 기본 설정입니다.
  # Azure Key Vault 이름은 하이픈을 쓸 수 없어 namespace에서 하이픈을 제거합니다.
  key_vault = {
    name                       = replace("kv-${var.namespace}", "-", "")
    resource_group_name        = var.resource_group_name
    location                   = var.location
    tenant_id                  = var.tenant_id
    sku_name                   = "standard"
    soft_delete_retention_days = 7
    purge_protection_enabled   = false
    tags                       = var.tags
  }

  # External Secrets Operator가 사용할 Azure Managed Identity와 Kubernetes ServiceAccount 정보입니다.
  external_secrets = {
    identity_name        = "id-${var.namespace}-external-secrets"
    federated_name       = "fic-${var.namespace}-external-secrets"
    service_account_name = "external-secrets"
    namespace            = "external-secrets"
    resource_group_name  = var.resource_group_name
    location             = var.location
    tags                 = var.tags
  }

  # AKS OIDC issuer와 ServiceAccount subject를 묶어 Workload Identity 인증을 구성합니다.
  federated_credential = {
    audience = ["api://AzureADTokenExchange"]
    issuer   = var.aks_oidc_issuer_url
    subject  = "system:serviceaccount:${local.external_secrets.namespace}:${local.external_secrets.service_account_name}"
  }

  # Terraform은 Secret을 쓰고, External Secrets Operator는 Secret을 읽기만 합니다.
  access_policies = {
    terraform = {
      tenant_id = var.tenant_id
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Purge",
      ]
    }

    external_secrets = {
      tenant_id = var.tenant_id
      secret_permissions = [
        "Get",
        "List",
      ]
    }
  }

  # 실행 주체가 로컬 사용자와 GitHub Actions 사이에서 바뀌어도 policy가 흔들리지 않도록,
  # Key Vault Secret 관리자 object ID는 변수에 적힌 고정 목록만 사용합니다.
  secret_admin_object_ids = toset(var.secret_admin_object_ids)

  # Key Vault에 저장할 Secret 이름과 값입니다.
  # k8s/was/external-secret.yaml의 remoteRef.key와 이름이 맞아야 합니다.
  secrets = {
    "kbeauty-db-url"         = var.db_url
    "kbeauty-db-user"        = var.db_user
    "kbeauty-db-password"    = var.db_password
    "kbeauty-redis-host"     = var.redis_host
    "kbeauty-redis-ssl-port" = var.redis_ssl_port
    "kbeauty-redis-password" = var.redis_password
  }
}
