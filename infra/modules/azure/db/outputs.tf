output "db_id" {
  description = "MySQL Flexible Server ID입니다."
  value       = azurerm_mysql_flexible_server.db.id
}

output "db_name" {
  description = "MySQL Flexible Server 이름입니다."
  value       = azurerm_mysql_flexible_server.db.name
}

output "db_fqdn" {
  description = "MySQL Flexible Server FQDN입니다."
  value       = azurerm_mysql_flexible_server.db.fqdn
}

#------------------------------------------------------------------
#AWS DMS 소스로 보낼 호스트 (fqdn - Azure apply 후 private IP로 교체 필요)
output "mysql_private_ip" {
  description = "MySQL Flexible Server FQDN (임시 - 실제 private IP로 교체 필요)"
  value       = azurerm_mysql_flexible_server.db.fqdn
}

# output "database_name" {
#   description = "생성되는 MySQL 데이터베이스 이름입니다."
#   value       = azurerm_mysql_flexible_database.app.name
# }
