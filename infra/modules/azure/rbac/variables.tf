variable "acr_id" {
  description = "ACR 리소스 ID입니다."
  type        = string
}

variable "resource_group_id" {
  description = "AGIC가 읽을 리소스 그룹 ID입니다."
  type        = string
}

variable "application_gateway_id" {
  description = "AGIC가 수정할 Application Gateway ID입니다."
  type        = string
}

variable "appgw_managed_identity_id" {
  description = "AGIC가 Application Gateway 업데이트 시 연결할 User Assigned Managed Identity 리소스 ID입니다."
  type        = string
}

variable "appgw_subnet_id" {
  description = "Application Gateway가 연결된 서브넷 ID입니다."
  type        = string
}

variable "aks_kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID입니다."
  type        = string
}

variable "agic_identity_object_id" {
  description = "AGIC 애드온 관리 ID의 object ID입니다."
  type        = string
}
