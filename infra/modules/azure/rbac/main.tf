resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_object_id
}

resource "azurerm_role_assignment" "agic_resource_group_reader" {
  name                 = "beebcb65-06c4-41ef-ad85-d53fea2fbe0b"
  scope                = var.resource_group_id
  role_definition_name = "Reader"
  principal_id         = var.agic_identity_object_id
}

resource "azurerm_role_assignment" "agic_application_gateway_contributor" {
  name                 = "91a92307-2b0b-423b-ae61-b85bc581f2e1"
  scope                = var.application_gateway_id
  role_definition_name = "Contributor"
  principal_id         = var.agic_identity_object_id
}

# AGIC가 App Gateway 구성을 갱신할 때 기존 User Assigned Identity를 다시 연결할 수 있어야 한다.
resource "azurerm_role_assignment" "agic_appgw_managed_identity_operator" {
  name                 = "4c9f8c91-bfbd-4f27-a60a-39ef0f838438"
  scope                = var.appgw_managed_identity_id # 권한을 부여할 대상 리소스 → App Gateway에 붙어있는 User Assigned Identity
  role_definition_name = "Managed Identity Operator"   # 특정 User Assigned Identity를 VM이나 App Gateway 같은 리소스에 assign(연결) 할 수 있는 권한
  principal_id         = var.agic_identity_object_id   # 권한을 받는 주체 → AGIC 자신의 Managed Identity
}

# 왜 AGIC한테 이 권한이 필요해?
# AGIC는 Ingress 규칙 변경이 생기면 App Gateway 설정을 직접 갱신해. 그 과정에서 App Gateway가 가진 User Assigned Identity 정보도 건드리게 되는데, 이때 Identity를 다시 연결하는 작업이 내부적으로 발생함.
# 이 권한 없이 AGIC가 App Gateway 설정을 PUT하면 → Identity 연결이 날아가거나 403 에러 남.

resource "azurerm_role_assignment" "agic_appgw_subnet_network_contributor" {
  name                 = "c00afb3c-8dfe-4dff-91bc-184b36b705cd"
  scope                = var.appgw_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.agic_identity_object_id
}
