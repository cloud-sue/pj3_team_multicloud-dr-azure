locals {
  redis_config = {
    name                = "redis-${var.namespace}"
    resource_group_name = var.resource_group_name
    location            = var.location
    subnet_id           = var.subnet_id

    sku_name                  = "Balanced_B0"
    high_availability_enabled = false
    public_network_access     = "Disabled"
    # Managed Redis hostname(redis-*.koreacentral.redis.azure.net)을 VNet 내부에서 사설 IP로 해석한다.
    private_dns_zone_name = "${var.location}.redis.azure.net"
  }
}
