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
