variable "resource_group_name" {
  description = "Key Vault와 Managed Identity를 생성할 리소스 그룹 이름입니다."
  type        = string
}

variable "location" {
  description = "Key Vault와 Managed Identity를 생성할 Azure 리전입니다."
  type        = string
}

variable "namespace" {
  description = "리소스 이름 prefix로 사용할 프로젝트 namespace입니다."
  type        = string
}

variable "tenant_id" {
  description = "Key Vault access policy와 Workload Identity에 사용할 Azure tenant ID입니다."
  type        = string
}

variable "secret_admin_object_ids" {
  description = "Key Vault Secret을 Terraform으로 관리할 Azure AD object ID 목록입니다."
  type        = list(string)
  default     = []
}

variable "aks_oidc_issuer_url" {
  description = "AKS Workload Identity federated credential에 사용할 OIDC issuer URL입니다."
  type        = string
}

variable "tags" {
  description = "생성되는 Azure 리소스에 공통으로 붙일 태그입니다."
  type        = map(string)
}

variable "db_url" {
  description = "WAS에서 사용할 JDBC URL입니다. Key Vault Secret kbeauty-db-url로 저장됩니다."
  type        = string
}

variable "db_user" {
  description = "WAS에서 사용할 DB 사용자명입니다. Key Vault Secret kbeauty-db-user로 저장됩니다."
  type        = string
}

variable "db_password" {
  description = "WAS에서 사용할 DB 비밀번호입니다. Key Vault Secret kbeauty-db-password로 저장됩니다."
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "WAS green 세션 저장소 Redis 호스트입니다. Key Vault Secret kbeauty-redis-host로 저장됩니다."
  type        = string
}

variable "redis_ssl_port" {
  description = "WAS green 세션 저장소 Redis TLS 포트입니다. Key Vault Secret kbeauty-redis-ssl-port로 저장됩니다."
  type        = string
}

variable "redis_password" {
  description = "WAS green 세션 저장소 Redis 비밀번호입니다. Key Vault Secret kbeauty-redis-password로 저장됩니다."
  type        = string
  sensitive   = true
}
