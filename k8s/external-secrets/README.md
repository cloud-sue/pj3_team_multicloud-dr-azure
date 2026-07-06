# External Secrets Operator

WAS Secret은 Git에 직접 올리지 않고 Azure Key Vault에서 가져옵니다.

## 1. Operator 설치

External Secrets Operator는 클러스터에 한 번만 설치하면 됩니다.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace \
  -f values.yaml
```

`values.yaml`은 `values.example.yaml`을 복사해서 만듭니다.

```bash
cp values.example.yaml values.yaml
```

`<external_secrets_client_id>` 값은 Terraform apply 후 출력되는 `external_secrets_client_id`를 넣습니다.

## 2. ClusterSecretStore 생성

`cluster-secret-store.example.yaml`을 복사해서 Terraform output 값으로 채운 뒤 적용합니다.

```bash
cp cluster-secret-store.example.yaml cluster-secret-store.yaml

# <tenant-id>, <key-vault-url> 값을 수정한 뒤 실행합니다.
kubectl apply -f cluster-secret-store.yaml
```

## 3. WAS sync

위 작업이 끝나면 `k8s/was/external-secret.yaml`이 Key Vault 값을 읽어 아래 Kubernetes Secret을 자동으로 생성합니다.

- `db-secret`
- `redis-secret`

그래서 Argo CD는 더 이상 Git에 없는 `db-secret.yaml`, `redis-secret.yaml`을 찾지 않습니다.
