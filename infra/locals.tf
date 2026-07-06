locals {
  org         = "azsis"
  project     = "kbeauty"
  environment = "dev"

  namespace = "${local.org}-${local.project}-${local.environment}"

  location = "koreacentral"

  tags = {
    owner = "kbeauty"
  }

  traffic_manager_secondary_target = try(trimspace(var.traffic_manager_secondary_target), "")

  # 수신자를 별도로 지정하지 않으면 ACME 등록 주소로 만료 알림을 보낸다.
  certificate_expiry_alert_emails = length(var.certificate_expiry_alert_emails) > 0 ? var.certificate_expiry_alert_emails : [var.acme_email_address]

  # AWS core remote state는 두 번째 apply부터 읽는다.
  # 첫 번째 apply에서는 enable_aws_core_remote_state=false라서 빈 값으로 유지되고,
  # AWS core apply 후 true로 바꾸면 CloudFront와 VPN 연결값을 자동으로 가져온다.
  aws_core_outputs        = try(one(data.terraform_remote_state.aws_core[*].outputs), {})
  aws_cloudfront_domain   = try(local.aws_core_outputs.cloudfront_domain, null)
  aws_vpn_tunnel1_address = try(trimspace(local.aws_core_outputs.vpn_tunnel1_address), "")
  aws_vpn_psk             = try(trimspace(local.aws_core_outputs.vpn_psk), "")
  manual_aws_tunnel_ip    = try(trimspace(var.aws_tunnel_ip), "")
  manual_vpn_shared_key   = try(trimspace(var.vpn_shared_key), "")
  azure_vpn_tunnel_ip     = local.manual_aws_tunnel_ip != "" ? local.manual_aws_tunnel_ip : local.aws_vpn_tunnel1_address
  azure_vpn_shared_key    = local.manual_vpn_shared_key != "" ? local.manual_vpn_shared_key : local.aws_vpn_psk

  aks = {
    kubernetes_version   = "1.36.0"
    auto_scaling_enabled = var.aks_auto_scaling_enabled
    availability_zones   = var.aks_availability_zones
    node_pools           = var.aks_node_pools
    service_cidr         = "10.10.0.0/16" # K8s 가상 네트워크 (실제 vnet과 겹치지 않음)
    dns_service_ip       = "10.10.0.10"   # K8s DNS 서비스 IP (service_cidr 범위 내에서 지정)
  }

  common_tags = merge(
    {
      project     = local.project
      environment = local.environment
      managed_by  = "terraform"
      org         = local.org
    },
    local.tags
  )
}
