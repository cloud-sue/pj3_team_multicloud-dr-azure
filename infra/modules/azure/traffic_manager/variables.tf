variable "resource_group_name" {
  description = "리소스 그룹 이름입니다."
  type        = string
}

variable "namespace" {
  description = "Traffic Manager 리소스 이름에 사용할 네임스페이스입니다."
  type        = string
}

variable "primary_target" {
  description = "Primary endpoint로 사용할 Application Gateway 공인 IP 또는 FQDN입니다."
  type        = string
}

variable "secondary_target" {
  description = "Secondary endpoint로 사용할 AWS 서비스 FQDN 또는 IP입니다. null이면 생성하지 않습니다."
  type        = string
  default     = null
}

variable "enable_secondary_endpoint" {
  description = "true이면 secondary endpoint를 생성합니다."
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스 태그입니다."
  type        = map(string)
  default     = {}
}
