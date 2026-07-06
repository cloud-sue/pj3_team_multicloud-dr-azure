output "id" {
  description = "Application Gateway ID입니다."
  value       = azurerm_application_gateway.this.id
}

output "name" {
  description = "Application Gateway 이름입니다."
  value       = azurerm_application_gateway.this.name
}

output "public_ip_id" {
  description = "Application Gateway 공인 IP ID입니다."
  value       = azurerm_public_ip.this.id
}

output "public_ip_address" {
  description = "Application Gateway 공인 IP 주소입니다."
  value       = azurerm_public_ip.this.ip_address
}

output "public_ip_fqdn" {
  description = "Application Gateway 공인 IP FQDN입니다."
  value       = local.public_ip.fqdn
}

output "waf_policy_id" {
  description = "Application Gateway WAF 정책 ID입니다."
  value       = azurerm_web_application_firewall_policy.this.id
}

output "ssl_key_vault_name" {
  description = "Application Gateway TLS 인증서를 저장하는 Key Vault 이름입니다."
  value       = try(azurerm_key_vault.appgw[0].name, null)
}

output "ssl_key_vault_id" {
  description = "Application Gateway TLS 인증서를 저장하는 Key Vault 리소스 ID입니다."
  value       = try(azurerm_key_vault.appgw[0].id, null)
}

output "ssl_certificate_name" {
  description = "Application Gateway에 등록되는 SSL 인증서 이름입니다."
  value       = local.https.certificate_name
}

output "managed_identity_client_id" {
  description = "Application Gateway가 Key Vault 인증서를 읽는 User Assigned Managed Identity client ID입니다."
  value       = try(azurerm_user_assigned_identity.appgw[0].client_id, null)
}

output "managed_identity_id" {
  description = "Application Gateway가 Key Vault 인증서를 읽는 User Assigned Managed Identity 리소스 ID입니다."
  value       = try(azurerm_user_assigned_identity.appgw[0].id, null)
}
