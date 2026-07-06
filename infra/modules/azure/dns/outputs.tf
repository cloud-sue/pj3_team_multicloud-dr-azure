output "zone_id" {
  description = "Public DNS Zone ID입니다."
  value       = azurerm_dns_zone.this.id
}

output "zone_name" {
  description = "Public DNS Zone 이름입니다."
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "도메인 등록기관에 설정할 Azure DNS 네임서버입니다."
  value       = azurerm_dns_zone.this.name_servers
}

output "root_a_record_fqdn" {
  description = "루트 도메인 A 레코드 FQDN입니다."
  value       = azurerm_dns_a_record.root.fqdn
}

output "www_cname_record_fqdn" {
  description = "www CNAME 레코드 FQDN입니다."
  value       = azurerm_dns_cname_record.www.fqdn
}
