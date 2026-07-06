resource "azurerm_container_registry" "this" {
  name                          = local.acr_name
  resource_group_name           = local.resource_group_name
  location                      = local.location
  sku                           = local.sku
  admin_enabled                 = local.admin_enabled
  public_network_access_enabled = local.public_network_access_enabled
  network_rule_bypass_option    = local.network_rule_bypass_option
  tags                          = local.tags
}
