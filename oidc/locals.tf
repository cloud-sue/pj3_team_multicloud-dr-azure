locals {
  # Terraform은 .env를 직접 읽지 않으므로 source .env로 TF_VAR_* 값을 export한 뒤 사용한다.
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # GitHub Actions OIDC를 허용할 repository와 Azure App Registration 기본 이름이다.
  github_repository        = "bespin-multi-cloud-3-azure/final_pj"
  application_display_name = "final-pj-github-actions-oidc"

  # 기본 권한은 subscription 전체 Contributor + User Access Administrator다.
  # Terraform이 AKS/AGIC/ACR RBAC role assignment를 만들려면 roleAssignments/write 권한이 필요하다.
  role_definition_name       = "Contributor"
  access_admin_role_name     = "User Access Administrator"
  role_assignment_scope_base = ""
  role_assignment_scope      = local.role_assignment_scope_base != "" ? local.role_assignment_scope_base : "/subscriptions/${local.subscription_id}"

  # Azure가 GitHub Actions OIDC 토큰을 검증할 때 사용하는 issuer/audience 값이다.
  main_branch_ref = "refs/heads/main"
  oidc_issuer     = "https://token.actions.githubusercontent.com"
  oidc_audience   = "api://AzureADTokenExchange"

  # main branch, pull_request, GitHub Environment(dev) workflow에서 Azure 로그인을 허용한다.
  main_credential_enabled = true
  pr_credential_enabled   = true
  dev_credential_enabled  = true

  # Azure Portal에서 구분하기 쉬운 Federated Credential 이름과 설명이다.
  main_credential_name     = "github-actions-main"
  pull_request_subject     = "repo:${local.github_repository}:pull_request"
  pull_request_name        = "github-actions-pull-request"
  main_branch_subject      = "repo:${local.github_repository}:ref:${local.main_branch_ref}"
  dev_environment_subject  = "repo:${local.github_repository}:environment:dev"
  dev_environment_name     = "github-actions-environment-dev"
  main_credential_desc     = "Allow GitHub Actions from the main branch."
  pull_request_desc        = "Allow GitHub Actions from pull_request events."
  dev_environment_desc     = "Allow GitHub Actions from the dev environment."
  federated_credential_aud = [local.oidc_audience]

  # 활성화된 workflow 조건만 Federated Credential 리소스로 생성한다.
  federated_credentials = merge(
    local.main_credential_enabled ? {
      main = {
        display_name = local.main_credential_name
        description  = local.main_credential_desc
        subject      = local.main_branch_subject
      }
    } : {},
    local.pr_credential_enabled ? {
      pull_request = {
        display_name = local.pull_request_name
        description  = local.pull_request_desc
        subject      = local.pull_request_subject
      }
    } : {},
    local.dev_credential_enabled ? {
      dev_environment = {
        display_name = local.dev_environment_name
        description  = local.dev_environment_desc
        subject      = local.dev_environment_subject
      }
    } : {}
  )
}
