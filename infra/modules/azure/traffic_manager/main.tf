resource "azurerm_traffic_manager_profile" "this" {
  name                   = local.names.profile
  resource_group_name    = var.resource_group_name
  profile_status         = local.profile.status
  traffic_routing_method = local.profile.routing_method
  tags                   = var.tags

  dns_config {
    relative_name = local.profile.dns_relative_name
    ttl           = local.profile.dns_ttl
  }

  monitor_config {
    protocol                     = local.profile.monitor_protocol
    port                         = local.profile.monitor_port
    path                         = local.profile.monitor_path
    expected_status_code_ranges  = local.profile.monitor_status_ranges
    interval_in_seconds          = local.profile.monitor_interval
    timeout_in_seconds           = local.profile.monitor_timeout
    tolerated_number_of_failures = local.profile.monitor_failure_count
  }
}

resource "azurerm_traffic_manager_external_endpoint" "primary" {
  name       = local.primary_endpoint.name
  profile_id = azurerm_traffic_manager_profile.this.id
  target     = local.primary_endpoint.target
  priority   = local.primary_endpoint.priority
  enabled    = local.primary_endpoint.enabled

  custom_header {
    name  = "Host"
    value = "www.sue019522.shop"
  }
}

resource "azurerm_traffic_manager_external_endpoint" "secondary" {
  count = local.profile.has_secondary_endpoint ? 1 : 0

  name       = local.secondary_endpoint.name
  profile_id = azurerm_traffic_manager_profile.this.id
  target     = local.secondary_endpoint.target
  priority   = local.secondary_endpoint.priority
  enabled    = local.secondary_endpoint.enabled

  depends_on = [azurerm_traffic_manager_external_endpoint.primary]
}
