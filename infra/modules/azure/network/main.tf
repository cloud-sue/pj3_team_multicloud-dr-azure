resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.namespace}"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = local.vnet.cidr_blocks
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = local.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.cidr_blocks

  # dynamic : 조건부 블록 생성
  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service
        actions = delegation.value.actions
      }
    }
  }
}
