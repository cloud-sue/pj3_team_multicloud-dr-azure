# GitHub Actions azure/login에서 client-id로 사용하는 값이다.
output "azure_client_id" {
  description = "GitHub secret AZURE_CLIENT_ID에 등록할 값입니다."
  value       = azuread_application.github_actions.client_id
}

# GitHub Actions azure/login에서 tenant-id로 사용하는 값이다.
output "azure_tenant_id" {
  description = "GitHub secret AZURE_TENANT_ID에 등록할 값입니다."
  value       = local.tenant_id
}

# GitHub Actions azure/login에서 subscription-id로 사용하는 값이다.
output "azure_subscription_id" {
  description = "GitHub secret AZURE_SUBSCRIPTION_ID에 등록할 값입니다."
  value       = local.subscription_id
}

# Role Assignment가 적용된 scope 확인용 output이다.
output "role_assignment_scope" {
  description = "Service Principal에 역할이 부여된 Azure scope입니다."
  value       = local.role_assignment_scope
}

# Azure Portal 또는 CLI에서 Service Principal을 확인할 때 사용할 수 있다.
output "service_principal_object_id" {
  description = "생성된 GitHub Actions Service Principal object ID입니다."
  value       = azuread_service_principal.github_actions.object_id
}

# Azure가 신뢰하도록 등록된 GitHub Actions subject 목록이다.
output "federated_credential_subjects" {
  description = "Azure가 신뢰하는 GitHub Actions OIDC subject 목록입니다."
  value = {
    for key, credential in azuread_application_federated_identity_credential.github_actions :
    key => credential.subject
  }
}
