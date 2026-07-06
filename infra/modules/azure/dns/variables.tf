variable "resource_group_name" {
  description = "리소스 그룹 이름입니다."
  type        = string
}

variable "root_a_record_ip" {
  description = "루트 도메인 A 레코드가 가리킬 Application Gateway 공인 IP입니다."
  type        = string
}

variable "traffic_manager_fqdn" {
  description = "www CNAME 레코드가 가리킬 Traffic Manager Profile FQDN입니다."
  type        = string
}

variable "tags" {
  description = "리소스 태그입니다."
  type        = map(string)
  default     = {}
}
