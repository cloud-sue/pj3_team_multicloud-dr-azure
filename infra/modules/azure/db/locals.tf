locals {
  db_config = {
    name                   = "kbeauty"
    database_name          = "kbeauty"
    resource_group_name    = var.resource_group_name
    location               = var.location
    administrator_login    = var.admin_username
    administrator_password = var.admin_password
    delegated_subnet_id    = var.subnet_id

    sku_name              = "GP_Standard_D2ds_v4"
    engine_version        = "8.0.21"
    backup_retention_days = 7
    storage_size_gb       = 20
  }
}
