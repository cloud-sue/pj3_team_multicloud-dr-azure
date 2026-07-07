
# AKS 설정 ================================================================================================================
aks_auto_scaling_enabled = true
aks_availability_zones   = ["1", "2", "3"]


aks_node_pools = {
  mgmtnp = {
    vm_size   = "Standard_D2s_v5"
    min_count = 2
    max_count = 3
    mode      = "System"
    node_labels = {
      workload = "system"
      purpose  = "core"
    }
  }

  appnp = {
    vm_size                     = "Standard_D2s_v5"
    temporary_name_for_rotation = "tmpappnp"
    min_count                   = 2
    max_count                   = 8
    mode                        = "User"
    node_labels = {
      workload = "app"
      purpose  = "web-was"
    }
  }

  monnp = {
    vm_size   = "Standard_D2s_v5"
    min_count = 1
    max_count = 3
    mode      = "User"
    node_labels = {
      workload = "monitoring"
      purpose  = "observability"
    }
  }
}

# NSG 설정 ================================================================================================================
# admin_source_address_prefixes는 snet-mgmt로 SSH/RDP 접속을 허용할 관리자 공인 IP CIDR 목록입니다. 
admin_source_address_prefixes = ["0.0.0.0/10"]

# Traffic Manager 설정 ====================================================================================================
# Azure만 먼저 apply할 때는 AWS remote state를 읽지 않고 Secondary Endpoint를 생성하지 않습니다.
# AWS core apply 이후 CloudFront 도메인을 자동 연동하려면 enable_aws_core_remote_state = true 로 바꿉니다.
# remote state 대신 직접 지정하려면 아래 값을 사용합니다.
enable_aws_core_remote_state = true
# traffic_manager_secondary_target = "d12fhgcbwkdlss.cloudfront.net"

# Kubernetes add-on 설정 ================================================================================================
# AKS가 아직 생성되지 않았거나 CI runner에서 kubeconfig를 만들 수 없으면 false로 둡니다.
# AKS 생성 이후 External Secrets Operator를 Terraform으로 설치할 때만 true로 바꿔 별도 apply합니다.
enable_kubernetes_addons = true

# External Secrets Operator CRD가 설치된 다음 apply에서만 true로 바꿉니다.
# kubernetes_manifest는 plan 시점에 ClusterSecretStore CRD를 조회하므로 Operator 설치와 같은 apply에 만들 수 없습니다.
enable_external_secrets_cluster_store = true

# Terraform apply를 실행할 수 있는 주체들을 고정 목록으로 관리한다.
# 팀원이 로컬 apply를 해야 하면 해당 Azure AD 사용자 object ID도 여기에 추가한다.
key_vault_secret_admin_object_ids = [
  "feffdc93-e27f-43b7-85dc-f677d7708373", # GitHub Actions Azure OIDC 앱
  "bff6c6e2-e884-437d-be3e-16a3d2dbd8f1", # 수현1
  "b38bc5db-4f6e-493b-9f2c-b442b2953532", # 가영
  "abb85fc9-80d9-45bf-9ba7-70f50da69d61", # 상일
]



# VPN 설정 ================================================================================================================
# AWS VPN apply 후 채울 값들
aws_tunnel_ip  = "13.125.136.125" # AWS VPN Connection → 터널 세부 정보 → 외부 IP
aws_vpc_cidr   = "192.0.0.0/16"
vpn_shared_key = "TOdzL4tV8GqhGKRDCu8LCqPManVt_XiO" # AWS apply 후 output 입력
