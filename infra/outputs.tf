output "resource_group_name" {
  description = "Azure 리소스 그룹 이름입니다."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "가상 네트워크 ID입니다."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "논리 이름별 서브넷 ID입니다."
  value       = module.network.subnet_ids
}

output "acr_id" {
  description = "ACR ID입니다."
  value       = module.acr.id
}

output "acr_name" {
  description = "ACR 이름입니다."
  value       = module.acr.name
}

output "acr_login_server" {
  description = "ACR 로그인 서버 주소입니다."
  value       = module.acr.login_server
}

output "agw_id" {
  description = "Application Gateway ID입니다."
  value       = module.agw.id
}

output "agw_name" {
  description = "Application Gateway 이름입니다."
  value       = module.agw.name
}

output "agw_public_ip_address" {
  description = "Application Gateway 공인 IP 주소입니다."
  value       = module.agw.public_ip_address
}

output "agw_public_ip_fqdn" {
  description = "Application Gateway 공인 IP FQDN입니다."
  value       = module.agw.public_ip_fqdn
}

output "agw_waf_policy_id" {
  description = "Application Gateway WAF 정책 ID입니다."
  value       = module.agw.waf_policy_id
}

output "agw_ssl_key_vault_name" {
  description = "Application Gateway TLS 인증서를 저장하는 Key Vault 이름입니다."
  value       = module.agw.ssl_key_vault_name
}

output "agw_ssl_key_vault_id" {
  description = "Application Gateway TLS 인증서를 저장하는 Key Vault 리소스 ID입니다."
  value       = module.agw.ssl_key_vault_id
}

output "agw_ssl_certificate_name" {
  description = "Application Gateway와 AGIC Ingress에서 참조하는 SSL 인증서 이름입니다."
  value       = module.agw.ssl_certificate_name
}

output "agw_managed_identity_client_id" {
  description = "Application Gateway가 Key Vault 인증서를 읽는 Managed Identity client ID입니다."
  value       = module.agw.managed_identity_client_id
}

output "aks_cluster_id" {
  description = "AKS 클러스터 ID입니다."
  value       = module.aks.id
}

output "aks_cluster_name" {
  description = "AKS 클러스터 이름입니다."
  value       = module.aks.name
}

output "aks_oidc_issuer_url" {
  description = "AKS Workload Identity에서 사용하는 OIDC issuer URL입니다."
  value       = module.aks.oidc_issuer_url
}

output "tenant_id" {
  description = "External Secrets Operator ClusterSecretStore에 넣을 Azure tenant ID입니다."
  value       = data.azurerm_client_config.current.tenant_id
}

output "key_vault_name" {
  description = "WAS Secret을 저장하는 Azure Key Vault 이름입니다."
  value       = module.keyvault.name
}

output "key_vault_uri" {
  description = "External Secrets Operator ClusterSecretStore에 넣을 Key Vault URL입니다."
  value       = module.keyvault.vault_uri
}

output "external_secrets_client_id" {
  description = "External Secrets Operator ServiceAccount annotation에 넣을 Managed Identity client ID입니다."
  value       = module.keyvault.external_secrets_client_id
}

output "redis_name" {
  description = "Azure Cache for Redis 이름입니다."
  value       = module.redis.name
}

output "redis_hostname" {
  description = "Azure Cache for Redis 호스트 이름입니다."
  value       = module.redis.hostname
}

output "redis_port" {
  description = "Azure Cache for Redis non-SSL 포트입니다."
  value       = module.redis.port
}

output "redis_ssl_port" {
  description = "Azure Cache for Redis SSL 포트입니다."
  value       = module.redis.ssl_port
}

output "redis_primary_access_key" {
  description = "Azure Cache for Redis 기본 액세스 키입니다."
  value       = module.redis.primary_access_key
  sensitive   = true
}

output "traffic_manager_name" {
  description = "Traffic Manager Profile 이름입니다."
  value       = module.traffic_manager.name
}

output "traffic_manager_fqdn" {
  description = "Traffic Manager Profile FQDN입니다."
  value       = module.traffic_manager.fqdn
}

output "traffic_manager_primary_endpoint_id" {
  description = "Traffic Manager Primary endpoint ID입니다."
  value       = module.traffic_manager.primary_endpoint_id
}

output "traffic_manager_secondary_endpoint_id" {
  description = "Traffic Manager Secondary endpoint ID입니다."
  value       = module.traffic_manager.secondary_endpoint_id
}

output "dns_zone_name" {
  description = "Public DNS Zone 이름입니다."
  value       = module.dns.zone_name
}

output "dns_name_servers" {
  description = "도메인 등록기관에 설정할 Azure DNS 네임서버입니다."
  value       = module.dns.name_servers
}

output "dns_a_record_fqdns" {
  description = "생성된 A 레코드 FQDN 목록입니다."
  value = {
    "@" = module.dns.root_a_record_fqdn
  }
}

output "dns_cname_record_fqdns" {
  description = "생성된 CNAME 레코드 FQDN 목록입니다."
  value = {
    "www" = module.dns.www_cname_record_fqdn
  }
}

#--------------------------------------------------------
#AWS에서 읽을 값
#AWS Customer Gateway에 등록할 IP
output "vpn_gateway_public_ip" {
  value = module.vpn.vpn_gateway_public_ip
}

# DMS 소스 엔드포인트 호스트
output "mysql_private_ip" {
  value = module.db.mysql_private_ip
}
