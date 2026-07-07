# 인프라

`final_pj`에서 사용하는 Azure 인프라를 구성하는 Terraform 코드입니다.

## 모듈

- `network`: 리소스 그룹의 VNet, AKS 서브넷, 사설 DB 서브넷을 구성합니다.
- `acr`: Azure Container Registry를 구성합니다.
- `aks`: ACR 이미지 풀 권한이 있는 Azure Kubernetes Service 클러스터를 구성합니다.
- `db`: 사설 서브넷에 Azure Database for MySQL Flexible Server를 구성합니다.
- `redis`: 세션 저장용 Azure Cache for Redis를 `snet-redis` 전용 서브넷에 구성합니다.

## 사용 방법

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

적용하기 전에 전역에서 고유한 `acr_name`을 설정해야 합니다. MySQL과 Redis는 사설 서브넷을 사용하므로 애플리케이션은 일반적으로 AKS처럼 VNet 내부에서 접속해야 합니다. Redis는 `snet-redis`에 배치되며 NSG 규칙은 `snet-aks`에서 Redis 포트로 들어오는 트래픽만 허용합니다.

## 원격 state 사용

팀원들과 Terraform state를 공유하려면 Azure Storage에 state backend를 만든 뒤 초기화할 때 backend 값을 전달합니다.

```bash
terraform init \
  -backend-config="resource_group_name=<state-rg>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=<state-container>" \
  -backend-config="key=final_pj/dev.tfstate"
```

`terraform.tfvars`에는 실제 Azure 구독 ID를 `subscription_id`에 설정합니다. `terraform.tfvars`는 `.gitignore`에 포함되어 있으므로 저장소에는 올라가지 않습니다.

## TLS 인증서 만료 알림

App Gateway용 TLS 인증서는 전용 Key Vault에서 관리합니다. 기본 설정은 인증서 만료 30일 전에 Key Vault의 `EmailContacts` 알림을 발송합니다. 수신자를 지정하지 않으면 `acme_email_address`가 수신자가 됩니다.

```hcl
enable_certificate_expiry_alert = true
certificate_expiry_alert_days   = 30
certificate_expiry_alert_emails = ["ops@example.com", "security@example.com"]
```

알림은 `azurerm_key_vault_certificate.ssl`로 Terraform이 Key Vault에 import하는 인증서에 적용됩니다. 적용 후 Azure Portal의 Key Vault → **Certificates** → 해당 인증서 → **Certificate Operation**에서 lifetime action과 만료일을 확인할 수 있습니다.

## TLS 인증서 Slack 알림

Slack 알림은 Key Vault Event Grid 이벤트를 Azure Function으로 전달한 뒤 Incoming Webhook에 전송합니다. 이메일 알림과 별개로 동작하며 `CertificateNearExpiry`와 `CertificateExpired` 이벤트를 모두 보냅니다.

`.env`에 다음 값을 넣고, apply 전에 현재 셸로 불러옵니다. `.env`는 Git에서 제외되며, 템플릿은 [`.env.example`](.env.example)에 있습니다.

```bash
set -a
source .env
set +a
```

```bash
TF_VAR_enable_certificate_slack_alert=true
TF_VAR_slack_webhook_url="https://hooks.slack.com/services/REPLACE_ME"
```

Webhook URL은 Terraform의 민감 변수로 처리되지만 원격 state에는 저장될 수 있으므로, state backend 접근 권한도 제한해야 합니다.

## 트러블슈팅

### AWS CloudFront remote state가 없어서 Azure apply가 실패하는 경우

#### 증상

Azure 인프라를 먼저 CI/CD로 apply할 때 AWS 인프라가 아직 생성되지 않았다면, AWS core remote state의 `cloudfront_domain` output을 읽는 단계에서 실패할 수 있습니다.

예상되는 원인은 다음과 같습니다.

- `aws/core/terraform.tfstate`가 아직 S3 backend에 없음
- AWS core는 아직 apply 전이라 `cloudfront_domain` output이 없음
- Azure만 먼저 apply해야 하는데 Terraform이 AWS remote state를 조회함

#### 해결

Azure만 먼저 apply할 때는 `terraform.tfvars`에서 AWS remote state 조회를 끕니다.

```hcl
enable_aws_core_remote_state = false
# traffic_manager_secondary_target = "d12fhgcbwkdlss.cloudfront.net"
```

이 상태에서는 Traffic Manager의 AWS Secondary Endpoint를 생성하지 않고, `www` CNAME은 Azure Traffic Manager FQDN을 계속 바라봅니다. 따라서 AWS 인프라가 없어도 Azure apply가 실패하지 않습니다.

```bash
cd final_pj/infra
terraform plan
terraform apply
```

#### AWS 생성 이후 다시 연결

AWS core 인프라를 apply해서 CloudFront가 생성되고 remote state에 `cloudfront_domain` output이 생긴 뒤에는 다시 켭니다.

```hcl
enable_aws_core_remote_state = true
```

그 다음 Azure 인프라를 다시 apply하면 Terraform이 AWS remote state에서 CloudFront DNS를 읽고 Traffic Manager Secondary Endpoint를 생성합니다.

```bash
cd final_pj_aws/infra/core
terraform apply

cd final_pj/infra
terraform apply
```

remote state를 쓰지 않고 CloudFront 도메인을 직접 넣고 싶다면 아래처럼 지정합니다.

```hcl
enable_aws_core_remote_state    = false
traffic_manager_secondary_target = "d12fhgcbwkdlss.cloudfront.net"
```
