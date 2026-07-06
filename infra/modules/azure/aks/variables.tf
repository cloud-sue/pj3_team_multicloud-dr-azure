variable "namespace" {
  description = "AKS 리소스 이름에 사용할 네임스페이스입니다."
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
  description = "AKS 노드 풀이 배치될 서브넷 ID입니다."
  type        = string
}

variable "application_gateway_id" {
  description = "AGIC add-on이 사용할 Application Gateway ID입니다."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS Kubernetes 버전입니다. null로 두면 Azure 기본 버전을 사용합니다."
  type        = string
  default     = null
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

variable "aks_service_cidr" {
  description = "AKS Kubernetes Service에 사용할 CIDR입니다. VNet/서브넷 대역과 겹치면 안 됩니다."
  type        = string
  default     = "10.2.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "AKS CoreDNS 서비스 IP입니다. aks_service_cidr 범위 안에 있어야 합니다."
  type        = string
  default     = "10.2.0.10"
}

variable "tags" {
  description = "리소스 태그입니다."
  type        = map(string)
  default     = {}
}
