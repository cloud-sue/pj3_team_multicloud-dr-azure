output "id" {
  description = "Traffic Manager Profile ID입니다."
  value       = azurerm_traffic_manager_profile.this.id
}

output "name" {
  description = "Traffic Manager Profile 이름입니다."
  value       = azurerm_traffic_manager_profile.this.name
}

output "fqdn" {
  description = "Traffic Manager Profile FQDN입니다."
  value       = azurerm_traffic_manager_profile.this.fqdn
}

output "primary_endpoint_id" {
  description = "Primary Traffic Manager endpoint ID입니다."
  value       = azurerm_traffic_manager_external_endpoint.primary.id
}

output "secondary_endpoint_id" {
  description = "Secondary Traffic Manager endpoint ID입니다."
  value       = try(azurerm_traffic_manager_external_endpoint.secondary[0].id, null)
}
