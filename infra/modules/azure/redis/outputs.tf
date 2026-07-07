output "id" {
  description = "Azure Cache for Redis ID입니다."
  value       = azurerm_managed_redis.this.id
}

output "name" {
  description = "Azure Managed Redis 이름입니다."
  value       = azurerm_managed_redis.this.name
}

output "hostname" {
  description = "Azure Managed Redis 호스트 이름입니다."
  value       = azurerm_managed_redis.this.hostname
}

output "port" {
  description = "Azure Managed Redis TLS 포트입니다."
  value       = azurerm_managed_redis.this.default_database[0].port
}

output "ssl_port" {
  description = "Azure Managed Redis TLS 포트입니다."
  value       = azurerm_managed_redis.this.default_database[0].port
}

output "primary_access_key" {
  description = "Azure Managed Redis 기본 액세스 키입니다."
  value       = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive   = true
}
