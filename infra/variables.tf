variable "subscription_id" {
  description = "Azure 구독 ID입니다. .env의 TF_VAR_subscription_id로 주입합니다."
  type        = string
}

variable "aks_auto_scaling_enabled" {
  description = "AKS 노드 풀의 자동 스케일링 사용 여부입니다."
  type        = bool
  default     = true
}

variable "aks_availability_zones" {
  description = "AKS 노드 풀에 사용할 가용 영역 목록입니다."
  type        = list(string)
  default     = []
}

variable "aks_node_pools" {
  description = "AKS 노드 풀 구성입니다. mgmt01은 기본 시스템 노드 풀로 사용합니다."
  type = map(object({
    vm_size                     = string
    min_count                   = number
    max_count                   = number
    mode                        = string
    node_labels                 = optional(map(string), {})
    node_taints                 = optional(list(string), [])
    temporary_name_for_rotation = optional(string)
  }))
}

variable "admin_source_address_prefixes" {
  description = "snet-mgmt로 SSH/RDP 접속을 허용할 관리자 공인 IP CIDR 목록입니다."
  type        = list(string)
  default     = []
}

variable "traffic_manager_secondary_target" {
  description = "Traffic Manager secondary endpoint로 사용할 AWS 서비스 FQDN 또는 IP입니다. Route53 자체가 아니라 Route53이 가리키는 ALB/CloudFront/EC2 등의 대상이어야 합니다."
  type        = string
  default     = null
}

variable "enable_aws_core_remote_state" {
  description = "true이면 AWS core Terraform remote state에서 CloudFront 도메인과 VPN tunnel/PSK 값을 읽어 두 번째 apply부터 Azure 연결에 사용합니다."
  type        = bool
  default     = false
}

variable "enable_kubernetes_addons" {
  description = "true이면 AKS kubeconfig를 사용하는 Helm/Kubernetes add-on 리소스를 Terraform에서 관리합니다. AKS 생성 후 별도 apply에서 켭니다."
  type        = bool
  default     = false
}

variable "enable_external_secrets_cluster_store" {
  description = "true이면 External Secrets Operator CRD 설치 이후 ClusterSecretStore를 생성합니다. enable_kubernetes_addons=true로 Operator를 먼저 적용한 뒤 켭니다."
  type        = bool
  default     = false
}

# CI/CD에서 사용하는 Azure OIDC 앱처럼, 현재 실행 주체와 별도로
# Key Vault Secret을 읽고 갱신해야 하는 Azure AD object ID를 추가합니다.
variable "key_vault_secret_admin_object_ids" {
  description = "Key Vault Secret을 Terraform으로 관리할 추가 Azure AD object ID 목록입니다. GitHub Actions OIDC 앱 등을 넣습니다."
  type        = list(string)
  default     = []
}

variable "appgw_enable_https" {
  description = "true이면 AppGW에 443 포트, Key Vault 인증서, Managed Identity 권한을 구성합니다."
  type        = bool
  default     = true
}

variable "appgw_ssl_hostname" {
  description = "AppGW HTTPS listener와 Kubernetes Ingress host에 사용할 도메인입니다."
  type        = string
  default     = "www.sue019522.shop"
}

variable "appgw_ssl_certificate_name" {
  description = "AppGW와 Ingress annotation에서 참조할 SSL 인증서 이름입니다."
  type        = string
  default     = "www-sue019522-shop"
}

variable "appgw_ssl_certificate_key_vault_secret_id" {
  description = "이미 Key Vault에 업로드된 PFX 인증서 Secret ID입니다. Terraform으로 import할 때는 null로 둡니다."
  type        = string
  default     = null
}

variable "appgw_import_ssl_certificate" {
  description = "true이면 appgw_ssl_certificate_pfx_base64 값을 AppGW 전용 Key Vault로 import합니다."
  type        = bool
  default     = false
}

variable "appgw_ssl_certificate_pfx_base64" {
  description = "Terraform으로 import할 PFX 인증서 base64 문자열입니다. appgw_import_ssl_certificate=true일 때 사용합니다."
  type        = string
  sensitive   = true
  default     = null
}

variable "appgw_ssl_certificate_password" {
  description = "PFX 인증서 비밀번호입니다. 비밀번호가 없으면 null로 둡니다."
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_acme_certificate" {
  description = "true이면 Terraform ACME Provider로 Let's Encrypt 인증서를 발급해 AppGW Key Vault 인증서로 import합니다."
  type        = bool
  default     = true
}

variable "acme_server_url" {
  description = "ACME CA directory URL입니다. 운영 Let's Encrypt를 기본값으로 사용합니다."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "acme_email_address" {
  description = "Let's Encrypt 계정 등록에 사용할 이메일 주소입니다."
  type        = string
  default     = "admin@sue019522.shop"
}

variable "enable_certificate_expiry_alert" {
  description = "true이면 Key Vault 인증서 만료 임박 시 등록된 이메일 수신자에게 알림을 보냅니다."
  type        = bool
  default     = true
}

variable "certificate_expiry_alert_emails" {
  description = "인증서 만료 알림을 받을 이메일 주소 목록입니다. 비워두면 acme_email_address를 사용합니다."
  type        = list(string)
  default     = []
}

variable "certificate_expiry_alert_days" {
  description = "Key Vault가 인증서 만료 임박 알림을 보낼 기준 일수입니다."
  type        = number
  default     = 30

  validation {
    condition     = var.certificate_expiry_alert_days > 0
    error_message = "certificate_expiry_alert_days는 1일 이상이어야 합니다."
  }
}

variable "enable_certificate_slack_alert" {
  description = "true이면 Key Vault 인증서 만료 이벤트를 Slack으로 전송합니다."
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL입니다. .env의 TF_VAR_slack_webhook_url로만 주입합니다."
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.slack_webhook_url == null || can(regex("^https://hooks\\.slack\\.com/services/", var.slack_webhook_url))
    error_message = "slack_webhook_url은 Slack Incoming Webhook URL이어야 합니다."
  }
}

variable "acme_dns_zone_name" {
  description = "DNS-01 TXT 레코드를 생성할 Azure DNS Zone 이름입니다."
  type        = string
  default     = "sue019522.shop"
}

variable "acme_dns_resource_group_name" {
  description = "Azure DNS Zone이 들어있는 리소스 그룹 이름입니다. null이면 현재 Terraform 리소스 그룹을 사용합니다."
  type        = string
  default     = null
}

variable "acme_azure_auth_method" {
  description = "lego Azure DNS provider 인증 방식입니다. 로컬은 cli, CI 서비스 프린시펄은 env를 주로 사용합니다."
  type        = string
  default     = "cli"
}

variable "acme_azure_client_id" {
  description = "acme_azure_auth_method=env일 때 사용할 Azure AD 애플리케이션 client ID입니다."
  type        = string
  default     = ""
}

variable "acme_azure_client_secret" {
  description = "acme_azure_auth_method=env일 때 사용할 Azure AD 애플리케이션 client secret입니다."
  type        = string
  sensitive   = true
  default     = ""
}

variable "acme_certificate_p12_password" {
  description = "ACME provider가 생성하는 PFX/PKCS#12 인증서 비밀번호입니다."
  type        = string
  sensitive   = true
  default     = ""
}

variable "acme_dns_txt_ttl" {
  description = "DNS-01 challenge TXT 레코드 TTL입니다."
  type        = number
  default     = 60
}

variable "acme_dns_propagation_timeout" {
  description = "Azure DNS challenge 전파를 기다릴 최대 시간(초)입니다."
  type        = number
  default     = 180
}

##########가영############33

# VPN 설정 ================================================================================================================
variable "aws_tunnel_ip" {
  description = "AWS VPN Connection 터널 IP입니다. 비워두면 enable_aws_core_remote_state=true일 때 AWS remote state의 vpn_tunnel1_address를 사용합니다."
  type        = string
  default     = ""
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR 대역 (DMS가 속한 VPC)"
  type        = string
  default     = "192.0.0.0/16"
}

variable "vpn_shared_key" {
  description = "AWS-Azure VPN IPsec 공유키입니다. 비워두면 enable_aws_core_remote_state=true일 때 AWS remote state의 vpn_psk를 사용합니다."
  type        = string
  sensitive   = true
  default     = ""
}


variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}
