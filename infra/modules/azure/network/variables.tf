variable "namespace" {
  description = "네트워크 리소스 이름에 사용할 네임스페이스입니다."
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

variable "tags" {
  description = "리소스 태그입니다."
  type        = map(string)
  default     = {}
}

variable "admin_source_address_prefixes" {
  description = "snet-mgmt로 SSH/RDP 접속을 허용할 관리자 공인 IP CIDR 목록입니다."
  type        = list(string)
  default     = []
}
