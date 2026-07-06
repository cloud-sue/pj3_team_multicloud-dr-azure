locals {
  acr_name            = "azsiskbeautyacr"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku                           = "Basic"
  admin_enabled                 = false
  public_network_access_enabled = true
  network_rule_bypass_option    = "AzureServices"
}
