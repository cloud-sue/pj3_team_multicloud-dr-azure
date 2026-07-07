# 이 IP를 AWS Customer Gateway에 등록
output "vpn_gateway_public_ip" {
  value = azurerm_public_ip.vpn.ip_address
}
