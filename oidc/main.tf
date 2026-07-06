# 현재 Azure CLI 로그인 tenant 정보를 output에 사용한다.
data "azuread_client_config" "current" {}

# GitHub Actions OIDC 로그인을 대표하는 Azure App Registration을 만든다.
resource "azuread_application" "github_actions" {
  display_name = local.application_display_name
}

# App Registration이 실제 Azure 권한을 받을 수 있도록 Service Principal을 만든다.
resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

# GitHub Actions의 OIDC 토큰 subject를 Azure가 신뢰하도록 등록한다.
resource "azuread_application_federated_identity_credential" "github_actions" {
  for_each = local.federated_credentials

  application_id = azuread_application.github_actions.id
  display_name   = each.value.display_name
  description    = each.value.description
  audiences      = local.federated_credential_aud
  issuer         = local.oidc_issuer
  subject        = each.value.subject
}

# GitHub Actions Service Principal에 Azure 리소스 접근 권한을 부여한다.
resource "azurerm_role_assignment" "github_actions" {
  scope                = local.role_assignment_scope
  role_definition_name = local.role_definition_name
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "azurerm_role_assignment" "github_actions_access_admin" {
  scope                = local.role_assignment_scope
  role_definition_name = local.access_admin_role_name
  principal_id         = azuread_service_principal.github_actions.object_id
}
