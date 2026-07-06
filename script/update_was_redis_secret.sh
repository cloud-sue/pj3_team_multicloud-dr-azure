#!/usr/bin/env bash
set -euo pipefail

# 목적:
#   Terraform으로 생성한 Azure Managed Redis 접속 정보를 Kubernetes redis-secret에 반영합니다.
#   was-green은 Redis-backed HTTP session을 사용하므로 secret 변경 후 pod 재시작이 필요합니다.
#
# 주의:
#   이 스크립트는 /k8s/was/redis-secret.yaml 파일에 Redis access key를 기록합니다.
#   해당 파일은 .gitignore에 포함되어 저장소에는 올라가지 않도록 되어 있습니다.
#   실행하면 was-green pod가 재시작됩니다.
#
# 실행 위치:
#   /home/sue/pj_final/final_pj 에서 실행하는 것을 기준으로 작성했습니다.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${ROOT_DIR}/infra"
SECRET_FILE="${ROOT_DIR}/k8s/was/redis-secret.yaml"

read -r -p "redis-secret을 갱신하고 was-green pod를 재시작할까요? [y/N] " answer
case "${answer}" in
  y|Y|yes|YES) ;;
  *)
    echo "취소했습니다."
    exit 0
    ;;
esac

redis_host="$(terraform -chdir="${INFRA_DIR}" output -raw redis_hostname)"
redis_port="$(terraform -chdir="${INFRA_DIR}" output -raw redis_ssl_port)"
redis_password="$(terraform -chdir="${INFRA_DIR}" output -raw redis_primary_access_key)"

umask 077
cat > "${SECRET_FILE}" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: redis-secret
  namespace: app-was
type: Opaque
stringData:
  redis-host: ${redis_host}
  redis-ssl-port: "${redis_port}"
  redis-password: ${redis_password}
EOF

kubectl apply -f "${SECRET_FILE}"

# secret은 pod 시작 시 env로 주입되므로 기존 pod에는 자동 반영되지 않습니다.
kubectl -n app-was rollout restart deploy was-green
kubectl -n app-was rollout status deploy was-green --timeout=180s
kubectl -n app-was get pod -l app=was,version=green -o wide

echo "redis-secret 갱신과 was-green 재시작이 완료되었습니다."
