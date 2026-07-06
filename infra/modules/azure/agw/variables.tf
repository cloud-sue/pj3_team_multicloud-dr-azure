variable "namespace" {
  description = "Application Gateway 리소스 이름에 사용할 네임스페이스입니다."
  type        = string
}

variable "resource_group_name" {
  description = "리소스 그룹 이름입니다."
  type        = string
}

variable "location" {
  description = "Azure 리전입니다."
  type        = string
}

variable "subnet_id" {
  description = "Application Gateway가 배치될 전용 서브넷 ID입니다."
  type        = string
}

variable "tags" {
  description = "리소스 태그입니다."
  type        = map(string)
  default     = {}
}

variable "tenant_id" {
  description = "Application Gateway가 Key Vault 인증서를 읽을 Azure AD tenant ID입니다."
  type        = string
}

variable "enable_https" {
  description = "true이면 Application Gateway에 443 포트와 Key Vault 기반 SSL 인증서를 구성합니다."
  type        = bool
  default     = true
}

variable "ssl_hostname" {
  description = "HTTPS listener에 연결할 공개 도메인입니다."
  type        = string
  default     = "www.sue019522.shop"
}

variable "ssl_certificate_name" {
  description = "Application Gateway와 Key Vault에서 사용할 SSL 인증서 이름입니다."
  type        = string
  default     = "www-sue019522-shop"
}

variable "ssl_certificate_key_vault_secret_id" {
  description = "이미 Key Vault에 올려둔 PFX 인증서 Secret ID입니다. 비워두면 ssl_certificate_pfx_base64를 Terraform으로 import합니다."
  type        = string
  default     = null
}

variable "import_ssl_certificate" {
  description = "true이면 ssl_certificate_pfx_base64 값을 AppGW 전용 Key Vault certificate로 import합니다."
  type        = bool
  default     = false
}

variable "ssl_certificate_pfx_base64" {
  description = "Terraform으로 Key Vault에 import할 PFX 인증서의 base64 문자열입니다. import_ssl_certificate=true일 때 사용합니다."
  type        = string
  sensitive   = true
  default     = null
}

variable "ssl_certificate_password" {
  description = "PFX 인증서 비밀번호입니다. 비밀번호가 없는 PFX면 null로 둡니다."
  type        = string
  sensitive   = true
  default     = null
}
variable "certificate_admin_object_ids" {
  description = "AppGW TLS Key Vault 인증서를 import/refresh할 Azure AD object ID 목록입니다."
  type        = list(string)
  default     = []
}

variable "enable_certificate_expiry_alert" {
  description = "true이면 Key Vault 인증서 만료 임박 이메일 알림을 설정합니다."
  type        = bool
  default     = true
}

variable "certificate_expiry_alert_emails" {
  description = "Key Vault 인증서 만료 알림을 받을 이메일 주소 목록입니다."
  type        = list(string)
  default     = []
}

variable "certificate_expiry_alert_days" {
  description = "인증서 만료 전 이메일 알림을 발송할 기준 일수입니다."
  type        = number
  default     = 30
}
