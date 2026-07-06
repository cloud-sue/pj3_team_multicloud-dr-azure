output "id" {
  description = "ACR ID입니다."
  value       = azurerm_container_registry.this.id
}

output "name" {
  description = "ACR 이름입니다."
  value       = azurerm_container_registry.this.name
}

output "login_server" {
  description = "ACR 로그인 서버 주소입니다."
  value       = azurerm_container_registry.this.login_server
}
