output "vnet_id" {
  description = "가상 네트워크 ID입니다."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "가상 네트워크 이름입니다."
  value       = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  description = "AKS 서브넷 ID입니다."
  value       = azurerm_subnet.this["aks"].id
}

output "appgw_subnet_id" {
  description = "Application Gateway 서브넷 ID입니다."
  value       = azurerm_subnet.this["appgw"].id
}

output "mysql_subnet_id" {
  description = "MySQL 서브넷 ID입니다."
  value       = azurerm_subnet.this["mysql"].id
}

output "redis_subnet_id" {
  description = "Redis 서브넷 ID입니다."
  value       = azurerm_subnet.this["redis"].id
}

output "db_subnet_id" {
  description = "사설 데이터베이스 서브넷 ID입니다. MySQL용 별칭으로 유지합니다."
  value       = azurerm_subnet.this["mysql"].id
}

output "subnet_ids" {
  description = "논리 이름별 서브넷 ID입니다."
  value       = { for key, subnet in azurerm_subnet.this : key => subnet.id }
}

output "gateway_subnet_id" {
  value = azurerm_subnet.this["gateway"].id
}
