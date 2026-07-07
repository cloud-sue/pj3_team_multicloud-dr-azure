variable "resource_group_name" {
  description = "리소스 그룹 이름입니다."
  type        = string
}

variable "location" {
  description = "Azure 리전입니다."
  type        = string
}

variable "namespace" {
  description = "Redis 리소스 이름에 사용할 네임스페이스입니다."
  type        = string
}

variable "subnet_id" {
  description = "Redis가 배치될 전용 서브넷 ID입니다."
  type        = string
}

variable "vnet_id" {
  description = "Redis Private DNS Zone을 연결할 VNet ID입니다."
  type        = string
}

variable "tags" {
  description = "리소스 태그입니다."
  type        = map(string)
  default     = {}
}
