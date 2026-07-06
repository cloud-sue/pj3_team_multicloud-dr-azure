# WAS Kubernetes Manifests

`db-secret`, `redis-secret`은 Azure Key Vault와 External Secrets Operator로 생성합니다.
실제 접속 정보는 Git에 올리지 않고 Key Vault에만 저장합니다.

`kustomization.yaml`에는 Git에 없는 Secret 파일 대신 `external-secret.yaml`을 명시합니다.
Argo CD는 이 리소스를 배포하고, External Secrets Operator가 Key Vault 값을 읽어 Kubernetes Secret을 만듭니다.

로컬 테스트용으로 Secret YAML을 직접 만들고 싶을 때만 `db-secret.example.yaml`, `redis-secret.example.yaml`을 참고합니다.

```text
namespace: app-was
secret: db-secret
keys:
- db-url
- db-user
- db-password

secret: redis-secret
keys:
- redis-host
- redis-ssl-port
- redis-password
```

로컬에서 Secret 파일을 직접 만든 뒤 적용하는 예시:

```bash
cp db-secret.example.yaml db-secret.yaml
cp redis-secret.example.yaml redis-secret.yaml

# db-secret.yaml, redis-secret.yaml 안의 <...> 값을 실제 값으로 수정한 뒤 실행합니다.
kubectl apply -k .
```

또는 Secret YAML 파일을 만들지 않고 클러스터에 직접 Secret만 만들 수도 있습니다.

```bash
kubectl -n app-was create secret generic db-secret \
  --from-literal=db-url='<jdbc-url>' \
  --from-literal=db-user='<db-user>' \
  --from-literal=db-password='<db-password>'

kubectl -n app-was create secret generic redis-secret \
  --from-literal=redis-host='<redis-host>' \
  --from-literal=redis-ssl-port='6380' \
  --from-literal=redis-password='<redis-password>'
```

Argo CD 환경에서는 직접 만든 Secret보다 External Secrets Operator 방식을 사용합니다.
직접 만든 Secret은 GitOps 흐름 밖에서 관리되므로 재현성이 떨어집니다.

## 자동화 방법

Secret 생성도 자동화할 수 있습니다. 현재 프로젝트는 1번 방식으로 구성합니다.

1. External Secrets Operator
   - Azure Key Vault에 DB/Redis 값을 저장합니다.
   - Git에는 `ExternalSecret` 리소스만 올립니다.
   - 클러스터의 External Secrets Operator가 Key Vault에서 값을 읽어 `db-secret`, `redis-secret`을 생성합니다.

2. Sealed Secrets
   - Secret을 암호화해서 Git에 올립니다.
   - 클러스터 안의 Sealed Secrets Controller가 복호화해서 Kubernetes Secret을 생성합니다.

3. CI/CD에서 kubectl create secret 실행
   - GitHub Actions secret 값을 사용해 `kubectl create secret`을 실행합니다.
   - 구현은 빠르지만 GitOps 원칙에는 상대적으로 덜 맞습니다.

현재 프로젝트에서는 Azure를 사용하므로 External Secrets Operator + Azure Key Vault 방식이 가장 권장됩니다.
