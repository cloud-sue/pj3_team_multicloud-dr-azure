resource "azurerm_dns_zone" "this" {
  name                = local.dns_zone_config.name
  resource_group_name = local.dns_zone_config.resource_group_name
  tags                = local.dns_zone_config.tags
}

# @
resource "azurerm_dns_a_record" "root" {
  name                = local.root_a_record.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.dns_zone_config.resource_group_name
  ttl                 = local.root_a_record.ttl
  records             = local.root_a_record.records
  tags                = local.root_a_record.tags
}

# www
resource "azurerm_dns_cname_record" "www" {
  name                = local.www_cname_record.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.dns_zone_config.resource_group_name
  ttl                 = local.www_cname_record.ttl
  record              = local.www_cname_record.record
  tags                = local.www_cname_record.tags
}

# ACM certificate DNS validation
resource "azurerm_dns_cname_record" "acm_validation" {
  for_each = local.acm_validation_cname_records

  name                = each.value.name
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = local.dns_zone_config.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
  tags                = each.value.tags
}
