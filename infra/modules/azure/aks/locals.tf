locals {
  namespace              = var.namespace
  resource_group_name    = var.resource_group_name
  node_resource_group    = "${var.resource_group_name}-node-rg"
  location               = var.location
  subnet_id              = var.subnet_id
  application_gateway_id = var.application_gateway_id

  kubernetes_version     = var.kubernetes_version
  aks_node_pools         = var.aks_node_pools # map형태로 받아옴
  aks_availability_zones = var.aks_availability_zones
  tags                   = var.tags

  aks_auto_scaling_enabled = var.aks_auto_scaling_enabled
  aks_service_cidr         = var.aks_service_cidr
  aks_dns_service_ip       = var.aks_dns_service_ip

  cluster_name = "aks-${local.namespace}"
  dns_prefix   = "aks-${local.namespace}"

  system_node_pool = local.aks_node_pools["mgmtnp"]
  user_node_pools = {
    for name, pool in local.aks_node_pools : name => pool
    if name != "mgmtnp"
  }
}
