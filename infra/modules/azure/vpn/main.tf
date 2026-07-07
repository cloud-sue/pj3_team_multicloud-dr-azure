# -----------------------------------------------
# VPN Gateway용 퍼블릭 IP
# apply 후 이 IP를 AWS Customer Gateway에 등록
# -----------------------------------------------
resource "azurerm_public_ip" "vpn" {
  name                = "pip-vpn-${var.namespace}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"] # VpnGw1AZ SKU는 AZ 퍼블릭 IP 필수
  tags                = var.tags
}

# -----------------------------------------------
# Azure VPN Gateway
# RouteBased : AWS static_routes_only = true와 호환
# VpnGw1 SKU : DR용으로 적절한 성능/비용
# -----------------------------------------------
resource "azurerm_virtual_network_gateway" "main" {
  name                = "vpngw-${var.namespace}"
  resource_group_name = var.resource_group_name
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1AZ"
  active_active       = false
  bgp_enabled         = false # AWS 쪽도 static_routes_only라 BGP 미사용

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id # GatewaySubnet ID
  }

  tags = var.tags
}

# -----------------------------------------------
# Local Network Gateway - AWS VPC를 Azure에 등록
# AWS VPN apply 후 나오는 터널 IP를 aws_tunnel_ip에 채운 뒤 재 apply
# -----------------------------------------------
resource "azurerm_local_network_gateway" "aws" {
  count = var.aws_tunnel_ip != "" ? 1 : 0

  name                = "lng-aws-${var.namespace}"
  resource_group_name = var.resource_group_name
  location            = var.location

  gateway_address = var.aws_tunnel_ip
  address_space   = [var.aws_vpc_cidr]

  tags = var.tags
}

# -----------------------------------------------
# VPN Connection - Azure VPN GW ↔ AWS 터널 연결
# Local Network Gateway가 생성된 후에만 만들어짐
# -----------------------------------------------
resource "azurerm_virtual_network_gateway_connection" "aws" {
  count = var.aws_tunnel_ip != "" ? 1 : 0

  name                = "conn-aws-${var.namespace}"
  resource_group_name = var.resource_group_name
  location            = var.location

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.main.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[0].id

  shared_key = var.shared_key

  tags = var.tags
}
