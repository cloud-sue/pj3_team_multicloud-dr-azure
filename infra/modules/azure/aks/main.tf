resource "azurerm_kubernetes_cluster" "this" {
  name                = local.cluster_name
  location            = local.location
  resource_group_name = local.resource_group_name
  dns_prefix          = local.dns_prefix
  kubernetes_version  = local.kubernetes_version
  node_resource_group = local.node_resource_group

  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true

  # AKS 클러스터와 Application Gateway 통합 설정
  ingress_application_gateway {
    gateway_id = local.application_gateway_id
  }

  default_node_pool {
    name           = "mgmt"
    vm_size        = local.system_node_pool.vm_size
    vnet_subnet_id = local.subnet_id
    type           = "VirtualMachineScaleSets"
    zones          = local.aks_availability_zones

    auto_scaling_enabled = local.aks_auto_scaling_enabled
    node_count           = local.system_node_pool.min_count
    min_count            = local.aks_auto_scaling_enabled ? local.system_node_pool.min_count : null
    max_count            = local.aks_auto_scaling_enabled ? local.system_node_pool.max_count : null
    node_labels          = local.system_node_pool.node_labels

    upgrade_settings {
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
      drain_timeout_in_minutes      = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
    service_cidr      = local.aks_service_cidr
    dns_service_ip    = local.aks_dns_service_ip
  }

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = local.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = local.subnet_id
  mode                  = each.value.mode
  zones                 = local.aks_availability_zones
  temporary_name_for_rotation = coalesce(
    each.value.temporary_name_for_rotation,
    "tmp${each.key}"
  )

  auto_scaling_enabled = local.aks_auto_scaling_enabled
  node_count           = each.value.min_count
  min_count            = local.aks_auto_scaling_enabled ? each.value.min_count : null
  max_count            = local.aks_auto_scaling_enabled ? each.value.max_count : null
  node_labels          = each.value.node_labels
  node_taints          = each.value.node_taints

  upgrade_settings {
    max_surge = "10%"
  }

  tags = local.tags
}
