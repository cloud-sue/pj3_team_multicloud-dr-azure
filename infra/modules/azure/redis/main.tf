resource "azurerm_managed_redis" "this" {
  name                      = local.redis_config.name
  resource_group_name       = local.redis_config.resource_group_name
  location                  = local.redis_config.location
  sku_name                  = local.redis_config.sku_name
  high_availability_enabled = local.redis_config.high_availability_enabled
  public_network_access     = local.redis_config.public_network_access
  tags                      = var.tags

  default_database {
    access_keys_authentication_enabled = true
  }
}

resource "azurerm_private_dns_zone" "redis" {
  name                = local.redis_config.private_dns_zone_name
  resource_group_name = local.redis_config.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "pdnslink-${local.redis_config.name}"
  resource_group_name   = local.redis_config.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# snet-redis에 private endpoint를 두고 public access는 닫아 WAS pod에서만 Redis를 사용한다.
resource "azurerm_private_endpoint" "redis" {
  name                = "pe-${local.redis_config.name}"
  resource_group_name = local.redis_config.resource_group_name
  location            = local.redis_config.location
  subnet_id           = local.redis_config.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${local.redis_config.name}"
    private_connection_resource_id = azurerm_managed_redis.this.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}
