# GitHub Actions OIDC for Azure

이 Terraform 코드는 GitHub Actions가 Azure에 OIDC 방식으로 로그인할 수 있도록 Azure App Registration, Service Principal, Federated Credential, RBAC Role Assignment를 생성합니다.

## 생성되는 리소스

- Azure App Registration
- Azure Service Principal
- GitHub Actions용 Federated Identity Credential
  - `main` 브랜치 workflow
  - `pull_request` workflow
- Azure RBAC Role Assignment

## 사용 방법

먼저 Azure에 로그인한 상태에서 실행합니다. 이 작업은 OIDC를 만들기 위한 bootstrap 단계라서, 처음 한 번은 Azure 리소스와 Entra ID 앱을 만들 권한이 있는 계정이 필요합니다.

```bash
cd OIDC
cp .env.example .env
set -a
source .env
set +a
terraform init
terraform plan
terraform apply
```

적용 후 output 값을 GitHub repository secrets에 등록합니다.

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

`terraform apply` 전에 `.env`에는 아래 두 값이 있어야 합니다.

```text
TF_VAR_subscription_id=<Azure subscription id>
TF_VAR_tenant_id=<Azure tenant id>
```

## 권한 범위

기본값은 subscription 전체에 `Contributor` 역할을 부여합니다.

권한을 줄이고 싶으면 `locals.tf`에서 `role_assignment_scope_base`를 특정 리소스 그룹 scope로 지정하거나, plan 전용으로만 쓸 경우 `role_definition_name = "Reader"`로 낮춥니다.

## GitHub OIDC Subject

기본적으로 아래 두 subject를 Azure가 신뢰하도록 등록합니다.

```text
repo:bespin-multi-cloud-3-azure/final_pj:ref:refs/heads/main
repo:bespin-multi-cloud-3-azure/final_pj:pull_request
```
