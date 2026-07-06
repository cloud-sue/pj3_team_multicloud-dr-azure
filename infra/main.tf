resource "azurerm_resource_group" "this" {
  name     = "rg-${local.namespace}"
  location = local.location
  tags     = local.common_tags
}

data "azurerm_client_config" "current" {}

data "terraform_remote_state" "aws_core" {
  # 첫 번째 Azure apply 시점에는 AWS core state가 없을 수 있으므로 기본값은 false다.
  # AWS core apply 이후 두 번째 Azure apply에서 true로 바꾸면 CloudFront/VPN 값을 자동으로 읽는다.
  count = var.enable_aws_core_remote_state ? 1 : 0

  backend = "s3"

  config = {
    bucket = "tfstate-azsis-kbeauty"
    key    = "aws/core/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

module "network" {
  source = "./modules/azure/network"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  namespace           = local.namespace
  tags                = local.common_tags

  admin_source_address_prefixes = var.admin_source_address_prefixes
}

module "acr" {
  source = "./modules/azure/acr"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.common_tags
}

module "agw" {
  source = "./modules/azure/agw"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  namespace           = local.namespace
  subnet_id           = module.network.appgw_subnet_id
  tags                = local.common_tags
  tenant_id           = data.azurerm_client_config.current.tenant_id

  enable_https                        = var.appgw_enable_https
  ssl_hostname                        = var.appgw_ssl_hostname
  ssl_certificate_name                = var.appgw_ssl_certificate_name
  ssl_certificate_key_vault_secret_id = local.appgw_ssl_certificate_secret_id
  import_ssl_certificate              = local.appgw_import_ssl_certificate
  ssl_certificate_pfx_base64          = local.appgw_ssl_certificate_pfx_base64
  ssl_certificate_password            = local.appgw_ssl_certificate_password
  certificate_admin_object_ids        = var.key_vault_secret_admin_object_ids
  enable_certificate_expiry_alert     = var.enable_certificate_expiry_alert
  certificate_expiry_alert_emails     = local.certificate_expiry_alert_emails
  certificate_expiry_alert_days       = var.certificate_expiry_alert_days

  depends_on = [module.network]
}

module "aks" {
  source = "./modules/azure/aks"

  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  namespace              = local.namespace
  subnet_id              = module.network.aks_subnet_id
  application_gateway_id = module.agw.id
  tags                   = local.common_tags

  kubernetes_version       = local.aks.kubernetes_version
  aks_auto_scaling_enabled = local.aks.auto_scaling_enabled
  aks_availability_zones   = local.aks.availability_zones
  aks_node_pools           = local.aks.node_pools
  aks_service_cidr         = local.aks.service_cidr
  aks_dns_service_ip       = local.aks.dns_service_ip
}

module "rbac" {
  source = "./modules/azure/rbac"

  acr_id                         = module.acr.id
  resource_group_id              = azurerm_resource_group.this.id
  application_gateway_id         = module.agw.id
  appgw_managed_identity_id      = module.agw.managed_identity_id
  appgw_subnet_id                = module.network.appgw_subnet_id
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  agic_identity_object_id        = module.aks.agic_identity_object_id
}

###################가영############## 
module "db" {
  source = "./modules/azure/db"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  subnet_id           = module.network.mysql_subnet_id

  admin_username = var.admin_username
  admin_password = var.admin_password
}

module "redis" {
  source = "./modules/azure/redis"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  namespace           = local.namespace
  subnet_id           = module.network.redis_subnet_id
  vnet_id             = module.network.vnet_id
  tags                = local.common_tags
}

module "keyvault" {
  source = "./modules/azure/keyvault"

  resource_group_name     = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  namespace               = local.namespace
  tenant_id               = data.azurerm_client_config.current.tenant_id
  secret_admin_object_ids = var.key_vault_secret_admin_object_ids
  aks_oidc_issuer_url     = module.aks.oidc_issuer_url
  tags                    = local.common_tags

  db_url         = "jdbc:mysql://${module.db.db_fqdn}:3306/kbeauty?useSSL=true&serverTimezone=Asia/Seoul"
  db_user        = var.admin_username
  db_password    = var.admin_password
  redis_host     = module.redis.hostname
  redis_ssl_port = tostring(module.redis.ssl_port)
  redis_password = module.redis.primary_access_key
}

module "traffic_manager" {
  source = "./modules/azure/traffic_manager"

  resource_group_name = azurerm_resource_group.this.name
  namespace           = local.namespace
  primary_target      = module.agw.public_ip_fqdn
  # AWS가 아직 없으면 null로 두어 Secondary Endpoint 생성을 건너뜁니다.
  secondary_target          = local.traffic_manager_secondary_target != "" ? local.traffic_manager_secondary_target : local.aws_cloudfront_domain
  enable_secondary_endpoint = (local.traffic_manager_secondary_target != "" ? local.traffic_manager_secondary_target : try(local.aws_cloudfront_domain, "")) != ""
  tags                      = local.common_tags
}

module "dns" {
  source = "./modules/azure/dns"

  resource_group_name  = azurerm_resource_group.this.name
  root_a_record_ip     = module.agw.public_ip_address
  traffic_manager_fqdn = module.traffic_manager.fqdn
  tags                 = local.common_tags
}


module "vpn" {
  source = "./modules/azure/vpn"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  namespace           = local.namespace
  tags                = local.common_tags

  gateway_subnet_id = module.network.gateway_subnet_id

  # 첫 apply에서는 빈 값이라 VPN Gateway만 만들고 Connection은 건너뛴다.
  # AWS core apply 후에는 remote state의 vpn_tunnel1_address/vpn_psk를 자동 사용한다.
  # 수동 입력값(var.aws_tunnel_ip / var.vpn_shared_key)이 있으면 remote state보다 우선한다.
  aws_tunnel_ip = local.azure_vpn_tunnel_ip
  aws_vpc_cidr  = var.aws_vpc_cidr
  shared_key    = local.azure_vpn_shared_key
}
