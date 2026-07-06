output "id" {
  description = "생성된 Azure Key Vault 리소스 ID입니다."
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "생성된 Azure Key Vault 이름입니다."
  value       = azurerm_key_vault.this.name
}

output "vault_uri" {
  description = "External Secrets Operator ClusterSecretStore에 넣을 Key Vault URL입니다."
  value       = azurerm_key_vault.this.vault_uri
}

output "external_secrets_client_id" {
  description = "External Secrets Operator ServiceAccount annotation에 넣을 Managed Identity client ID입니다."
  value       = azurerm_user_assigned_identity.external_secrets.client_id
}

output "external_secrets_principal_id" {
  description = "Key Vault access policy에 연결된 Managed Identity principal ID입니다."
  value       = azurerm_user_assigned_identity.external_secrets.principal_id
}
