resource "azurerm_mysql_flexible_server" "db" {
  name                   = local.db_config.name
  resource_group_name    = local.db_config.resource_group_name
  location               = local.db_config.location
  administrator_login    = local.db_config.administrator_login
  administrator_password = local.db_config.administrator_password

  sku_name            = local.db_config.sku_name
  version             = local.db_config.engine_version
  delegated_subnet_id = local.db_config.delegated_subnet_id

  backup_retention_days = local.db_config.backup_retention_days

  storage {
    size_gb = local.db_config.storage_size_gb
  }

  lifecycle {
    ignore_changes = [
      zone,
    ]
  }
}

resource "azurerm_mysql_flexible_server_configuration" "time_zone" {
  name                = "time_zone"
  resource_group_name = local.db_config.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  value               = "+09:00"
}


#DMS가 SSL없이 접속하도록 허용
resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = "require_secure_transport"
  resource_group_name = local.db_config.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  value               = "OFF"
}

#binlog 값을 FULL로 바꾸고, DMS에서 읽을 수 있도록 설정
resource "azurerm_mysql_flexible_server_configuration" "binlog_row_image" {
  name                = "binlog_row_image"
  resource_group_name = local.db_config.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  value               = "FULL"
}

#binlog를 24시간 보관 - 이거는 더 알아봐야됨.
resource "azurerm_mysql_flexible_server_configuration" "binlog_expire_logs_seconds" {
  name                = "binlog_expire_logs_seconds"
  resource_group_name = local.db_config.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  value               = "86400"
}

resource "azurerm_mysql_flexible_database" "app" {
  name                = local.db_config.database_name
  resource_group_name = local.db_config.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
