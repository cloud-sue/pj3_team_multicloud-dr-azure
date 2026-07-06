# External Secrets Operator를 AKS에 설치합니다.
# 이 Helm chart가 ExternalSecret/ClusterSecretStore CRD를 만들기 때문에,
# Argo CD가 k8s/was/external-secret.yaml을 적용할 수 있습니다.
resource "helm_release" "external_secrets" {
  # AKS가 아직 없거나 CI runner에서 kubeconfig를 구성할 수 없는 1차 Azure apply에서는
  # Helm provider가 Kubernetes REST client를 만들지 못하므로 add-on 설치를 건너뜁니다.
  count = var.enable_kubernetes_addons ? 1 : 0

  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true

  # Workload Identity 설정을 Helm values로 주입합니다.
  # 이 ServiceAccount가 Key Vault용 Managed Identity를 위임받아 Secret을 읽습니다.
  values = [
    yamlencode({
      installCRDs = true
      serviceAccount = {
        name = "external-secrets"
        annotations = {
          "azure.workload.identity/client-id" = module.keyvault.external_secrets_client_id
        }
      }
      podLabels = {
        "azure.workload.identity/use" = "true"
      }
    })
  ]

  depends_on = [module.aks]
}

# WAS ExternalSecret이 참조하는 Azure Key Vault 연결 정보입니다.
# 이 리소스가 없으면 db-secret/redis-secret ExternalSecret이 Secret을 생성하지 못합니다.
resource "kubernetes_manifest" "external_secrets_cluster_secret_store" {
  # kubernetes_manifest는 plan 단계에서도 Kubernetes API schema 조회를 시도합니다.
  # Helm chart가 CRD를 설치한 다음 apply에서만 ClusterSecretStore를 활성화해야 합니다.
  count = var.enable_external_secrets_cluster_store ? 1 : 0

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "azure-keyvault"
    }
    spec = {
      provider = {
        azurekv = {
          authType = "WorkloadIdentity"
          tenantId = data.azurerm_client_config.current.tenant_id
          vaultUrl = module.keyvault.vault_uri
          serviceAccountRef = {
            name      = "external-secrets"
            namespace = "external-secrets"
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}
