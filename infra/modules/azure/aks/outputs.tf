output "id" {
  description = "AKS 클러스터 ID입니다."
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS 클러스터 이름입니다."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "AKS 클러스터 kubeconfig입니다."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Helm/Kubernetes provider가 사용할 AKS API 서버 주소입니다."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "Helm/Kubernetes provider가 사용할 클라이언트 인증서입니다."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  sensitive   = true
}

output "kube_config_client_key" {
  description = "Helm/Kubernetes provider가 사용할 클라이언트 키입니다."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "Helm/Kubernetes provider가 사용할 AKS CA 인증서입니다."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kubelet_identity_object_id" {
  description = "AKS kubelet identity 오브젝트 ID입니다."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "principal_id" {
  description = "AKS 시스템 할당 관리 ID의 principal ID입니다."
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

output "agic_identity_object_id" {
  description = "Application Gateway Ingress Controller 애드온 관리 ID의 object ID입니다."
  value       = azurerm_kubernetes_cluster.this.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}

output "oidc_issuer_url" {
  description = "AKS Workload Identity에서 사용하는 OIDC issuer URL입니다."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}
