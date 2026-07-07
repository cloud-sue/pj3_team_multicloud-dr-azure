resource "azurerm_network_security_group" "this" {
  # GatewaySubnet은 Azure 정책상 NSG 연결 불가 → 제외
  for_each = { for k, v in local.subnets : k => v if k != "gateway" }

  name                = "nsg-${each.value.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = {
    for rule in local.nsg_rule_list : rule.key => rule
  }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_key].name

  source_address_prefix        = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes      = each.value.source_address_prefixes
  destination_address_prefix   = each.value.destination_address_prefix
  destination_address_prefixes = each.value.destination_address_prefixes
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in local.subnets : k => v if k != "gateway" }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
