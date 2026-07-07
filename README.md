# Final PJ

K-Beauty 쇼핑몰 애플리케이션과 Azure 기반 운영 인프라를 함께 관리하는 저장소입니다.

React 프론트엔드, Spring Boot WAS, Kubernetes 배포 매니페스트, Terraform 인프라 코드, GitHub Actions CI/CD, Argo CD GitOps 설정을 포함합니다. 메인 서비스는 Azure AKS에서 운영하고, AWS DR 환경과 연동할 수 있도록 이미지와 Traffic Manager 구성이 준비되어 있습니다.

## 주요 구성

| 영역 | 경로 | 설명 |
| --- | --- | --- |
| WEB | `app/web_blue`, `app/web_green` | React 19 + Vite 프론트엔드. 상품 목록/상세, 로그인, 회원가입, 문의, 마이페이지 화면 제공 |
| WAS | `app/was_blue`, `app/was_green` | Java 17 + Spring Boot 백엔드. 상품, 인증, 문의, 서버 정보, 헬스체크 API 제공 |
| Kubernetes | `k8s/web`, `k8s/was` | WEB/WAS blue-green Deployment, Service, HPA, Ingress, Secret, Kustomize 설정 |
| Azure Infra | `infra` | Terraform으로 VNet, AKS, ACR, Application Gateway, MySQL, Redis, Key Vault, DNS, Traffic Manager, VPN 구성 |
| OIDC | `oidc` | GitHub Actions와 Azure 인증 연동을 위한 Terraform 코드 |
| Argo CD | `argocd` | AKS 애플리케이션과 AWS DR GitOps 애플리케이션 연결 설정 |
| Observability | `whatap` | Whatap 에이전트와 Kubernetes 배포 설정 |
| Scripts | `script` | 이미지 빌드, DR 테스트 리소스 생성, Secret 갱신 등 보조 스크립트 |

## 애플리케이션 기능

- 상품 목록 조회, 검색, 카테고리 필터
- 상품 상세 조회
- 회원가입, 로그인, 세션 복원, 로그아웃
- 로그인 사용자 문의 작성 및 문의 목록 조회
- 서버 배포 정보 표시
- `/api/healthz` 기반 헬스체크
- `/insert`, `/api/insert` 기반 초기 상품 데이터 적재

## 아키텍처 요약

```text
User
  -> Azure DNS / Traffic Manager
  -> Application Gateway + AGIC
  -> AKS Ingress
  -> WEB Service(active blue/green)
  -> WAS Service(active blue/green)
  -> Azure MySQL Flexible Server
  -> Azure Managed Redis
```

운영 환경은 Azure를 기본 Primary로 사용합니다. `infra`의 Traffic Manager는 Azure Application Gateway를 Primary endpoint로 두고, AWS CloudFront를 Secondary endpoint로 붙일 수 있습니다. AWS DR 리소스는 `../final_pj_aws` 저장소에서 관리합니다.

## 기술 스택

- Frontend: React 19, Vite 7, Vanilla CSS, Nginx
- Backend: Java 17, Spring Boot 4.0.5, Spring Web MVC, Spring Data JPA, JDBC, MyBatis starter, MySQL Connector/J, H2
- Runtime: Docker, Kubernetes, Kustomize, HPA
- Azure: AKS, ACR, Application Gateway/WAF, Azure DNS, Traffic Manager, Key Vault, MySQL Flexible Server, Managed Redis, VPN Gateway
- CI/CD: GitHub Actions, Argo CD, Terraform, TFLint, tfsec, Trivy
- Monitoring: Whatap

## 로컬 실행

### WAS

로컬에서는 H2 인메모리 DB를 사용하는 `local` 프로필로 실행합니다.

```bash
cd app/was_blue
SPRING_PROFILES_ACTIVE=local ./mvnw spring-boot:run
```

Green 버전을 확인하려면 `app/was_green`에서 같은 명령을 실행합니다.

```bash
curl http://localhost:8080/api/healthz
curl http://localhost:8080/api/products/all
```

### WEB

```bash
cd app/web_blue
npm install
npm run dev
```

기본 접속 주소는 `http://localhost:5173`입니다. WAS 주소는 `.env` 또는 브라우저 localStorage로 지정할 수 있습니다.

```bash
VITE_API_BASE_URL=http://localhost:8080
```

```javascript
localStorage.setItem("kbeautyApiBaseUrl", "http://localhost:8080")
```

## 빌드와 테스트

### WAS 테스트/빌드

```bash
cd app/was_blue
SPRING_PROFILES_ACTIVE=local ./mvnw test
./mvnw -DskipTests package
```

빌드 결과물은 `target/kbeauty-app.jar`입니다.

### WEB 빌드

```bash
cd app/web_blue
npm install
npm run build
```

빌드 결과물은 `dist/`에 생성됩니다.

## 컨테이너 이미지

Kubernetes 배포용 Dockerfile과 Compose 파일은 아래 경로에 있습니다.

```text
k8s/web/image_build/blue
k8s/web/image_build/green
k8s/was/image_build/blue
k8s/was/image_build/green
```

GitHub Actions CD 워크플로는 이미지를 ACR에 push하고, AWS DR에서 사용할 수 있도록 ECR에도 동일 이미지를 push합니다.

## Kubernetes 배포

```bash
kubectl apply -k k8s/web
kubectl apply -k k8s/was
```

Active 트래픽은 다음 Service 매니페스트의 selector로 결정합니다.

- WEB: `k8s/web/service-active.yaml`
- WAS: `k8s/was/was-service.yaml`

Blue-green 전환은 active Service의 `version: blue|green` selector를 변경하는 방식입니다.

## Azure 인프라 배포

```bash
cd infra
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

주요 Terraform 모듈은 다음 리소스를 생성합니다.

- `network`: VNet, AKS/AppGW/MySQL/Redis/Gateway 서브넷, NSG
- `acr`: Azure Container Registry
- `agw`: Application Gateway, WAF, TLS Key Vault 연동
- `aks`: AKS 클러스터와 node pool
- `db`: Azure Database for MySQL Flexible Server
- `redis`: Azure Managed Redis와 Private Endpoint
- `keyvault`: 애플리케이션 Secret과 External Secrets 연동
- `traffic_manager`: Azure Primary, AWS Secondary endpoint
- `dns`: root A record, `www` CNAME, ACM 검증 CNAME
- `vpn`: AWS VPC와 Site-to-Site VPN 연결

상세한 인프라 사용법과 인증서 알림 설정은 `infra/README.md`를 참고합니다.

## CI/CD

| Workflow | 설명 |
| --- | --- |
| `ci-web.yml` | WEB npm build, Docker build 검증 |
| `ci-was.yml` | WAS Maven test, Docker build 검증 |
| `ci-terraform.yml` | Terraform fmt/validate/tflint/tfsec/plan |
| `cd-web.yml` | WEB 이미지 build/scan/push, GitOps 매니페스트 이미지 태그 갱신 |
| `cd-was.yml` | WAS 이미지 build/scan/push, GitOps 매니페스트 이미지 태그 갱신 |
| `cd-terraform.yml` | Azure Terraform apply/destroy |

CD 워크플로는 inactive color를 대상으로 이미지를 갱신하고, smoke test 후 active Service 전환을 수행할 수 있도록 구성되어 있습니다.

## AWS DR 연동

이 저장소의 Azure Traffic Manager는 AWS CloudFront를 Secondary endpoint로 사용할 수 있습니다. AWS 쪽 리소스는 `../final_pj_aws`에서 생성합니다.

Azure만 먼저 배포해야 하는 경우 `infra/terraform.tfvars`에서 AWS remote state 조회를 끕니다.

```hcl
enable_aws_core_remote_state = false
```

AWS core 배포 후 다시 연결하려면 AWS remote state에 `cloudfront_domain` output이 생성된 상태에서 아래 값을 켭니다.

```hcl
enable_aws_core_remote_state = true
```

## 보안 주의사항

- `terraform.tfvars`, `.env`, Kubernetes Secret YAML에는 실제 비밀값이 들어갈 수 있으므로 커밋 전 반드시 확인합니다.
- 운영 DB 비밀번호, Redis 비밀번호, Slack Webhook, Cloud credential은 GitHub Secrets, Azure Key Vault, External Secrets로 관리합니다.
- WAS의 `application.properties`에 직접 적힌 접속 정보는 운영 배포 시 환경 변수 또는 Secret으로 덮어씁니다.
- 로그인/회원가입 구현은 프로젝트용 단순 세션 방식입니다. 운영 서비스에서는 비밀번호 해싱, HTTPS only cookie, CORS 제한, CSRF 방어를 강화해야 합니다.

## 참고 문서

- `app/web_blue/README.md`, `app/web_green/README.md`
- `app/was_blue/README.md`, `app/was_green/README.md`
- `infra/README.md`
- `oidc/README.md`
- `k8s/web/README.md`
- `k8s/was/README.md`
- `k8s/external-secrets/README.md`
