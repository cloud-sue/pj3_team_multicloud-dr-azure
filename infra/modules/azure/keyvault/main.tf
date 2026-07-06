# External Secrets Operator가 Azure Key Vault를 읽을 때 사용할 User Assigned Managed Identity입니다.
resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = local.external_secrets.identity_name
  resource_group_name = local.external_secrets.resource_group_name
  location            = local.external_secrets.location
  tags                = local.external_secrets.tags
}

# AKS ServiceAccount와 Managed Identity를 OIDC로 연결합니다.
# 이 설정 덕분에 Kubernetes Secret 없이 pod가 Azure 권한을 위임받을 수 있습니다.
resource "azurerm_federated_identity_credential" "external_secrets" {
  name                      = local.external_secrets.federated_name
  user_assigned_identity_id = azurerm_user_assigned_identity.external_secrets.id
  audience                  = local.federated_credential.audience
  issuer                    = local.federated_credential.issuer
  subject                   = local.federated_credential.subject
}

# WAS가 사용하는 DB/Redis 접속 정보를 저장하는 Key Vault입니다.
# 실제 민감 값은 Git이 아니라 이 Key Vault에만 저장합니다.
resource "azurerm_key_vault" "this" {
  name                       = local.key_vault.name
  resource_group_name        = local.key_vault.resource_group_name
  location                   = local.key_vault.location
  tenant_id                  = local.key_vault.tenant_id
  sku_name                   = local.key_vault.sku_name
  soft_delete_retention_days = local.key_vault.soft_delete_retention_days
  purge_protection_enabled   = local.key_vault.purge_protection_enabled

  tags = local.key_vault.tags
}

# 로컬 사용자와 GitHub Actions OIDC 앱처럼 Terraform을 실행하는 주체들이
# 기존 Key Vault Secret refresh와 갱신을 할 수 있도록 object ID별 권한을 부여합니다.
resource "azurerm_key_vault_access_policy" "secret_admins" {
  for_each = local.secret_admin_object_ids

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = local.access_policies.terraform.tenant_id
  object_id    = each.value

  secret_permissions = local.access_policies.terraform.secret_permissions
}

# External Secrets Operator는 Secret 값을 읽기만 하면 되므로 최소 권한만 부여합니다.
resource "azurerm_key_vault_access_policy" "external_secrets" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = local.access_policies.external_secrets.tenant_id
  object_id    = azurerm_user_assigned_identity.external_secrets.principal_id

  secret_permissions = local.access_policies.external_secrets.secret_permissions
}

# Terraform에서 생성된 DB/Redis 정보를 Key Vault Secret으로 저장합니다.
# Kubernetes에서는 k8s/was/external-secret.yaml이 같은 이름의 Secret을 참조합니다.
resource "azurerm_key_vault_secret" "this" {
  for_each = local.secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [
    azurerm_key_vault_access_policy.secret_admins,
  ]
}
