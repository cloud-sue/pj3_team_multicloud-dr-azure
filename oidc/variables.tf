# .env의 TF_VAR_subscription_id 환경변수로 주입한다.
variable "subscription_id" {
  description = "GitHub Actions OIDC가 접근할 Azure 구독 ID입니다."
  type        = string
}

# .env의 TF_VAR_tenant_id 환경변수로 주입한다.
variable "tenant_id" {
  description = "GitHub Actions OIDC App Registration을 만들 Azure Entra ID tenant ID입니다."
  type        = string
}
