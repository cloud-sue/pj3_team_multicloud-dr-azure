#!/usr/bin/env bash
set -euo pipefail

# 목적:
#   AWS DMS 동기화 테스트용 Azure Database for MySQL Flexible Server를
#   Terraform 상태와 분리해서 Azure CLI로 생성합니다.
#
# 기본 리소스 그룹:
#   rg-drtest
#
# 사용 예:
#   ./script/create_azure_mysql_drtest.sh
#
# 서버명은 Azure 전역에서 고유해야 하므로 필요하면 환경변수로 변경하세요.
#   MYSQL_SERVER_NAME=drtest-mysql-001 ./script/create_azure_mysql_drtest.sh
#
# AWS DMS Replication Instance의 공인 IP를 알고 있으면 방화벽을 함께 열 수 있습니다.
#   DMS_CLIENT_IP=1.2.3.4 ./script/create_azure_mysql_drtest.sh

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-drtest}"
LOCATION="${LOCATION:-koreacentral}"
MYSQL_SERVER_NAME="${MYSQL_SERVER_NAME:-azsis-drtest-${RANDOM}}"
MYSQL_DATABASE_NAME="${MYSQL_DATABASE_NAME:-kbeauty}"
MYSQL_ADMIN_USER="${MYSQL_ADMIN_USER:-testuser}"
MYSQL_VERSION="${MYSQL_VERSION:-8.0.21}"
MYSQL_SKU_NAME="${MYSQL_SKU_NAME:-Standard_B1ms}"
MYSQL_TIER="${MYSQL_TIER:-Burstable}"
MYSQL_STORAGE_SIZE_GB="${MYSQL_STORAGE_SIZE_GB:-32}"
DMS_CLIENT_IP="${DMS_CLIENT_IP:-}"

echo "Azure 계정 확인"
az account show --output table

read -r -s -p "MySQL 관리자 비밀번호를 입력하세요: " MYSQL_ADMIN_PASSWORD
echo

if [[ -z "${MYSQL_ADMIN_PASSWORD}" ]]; then
  echo "비밀번호가 비어 있습니다. 중단합니다."
  exit 1
fi

echo "리소스 그룹 생성 또는 확인: ${RESOURCE_GROUP}"
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output table

echo "MySQL Flexible Server 생성: ${MYSQL_SERVER_NAME}"
az mysql flexible-server create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${MYSQL_SERVER_NAME}" \
  --location "${LOCATION}" \
  --admin-user "${MYSQL_ADMIN_USER}" \
  --admin-password "${MYSQL_ADMIN_PASSWORD}" \
  --version "${MYSQL_VERSION}" \
  --tier "${MYSQL_TIER}" \
  --sku-name "${MYSQL_SKU_NAME}" \
  --storage-size "${MYSQL_STORAGE_SIZE_GB}" \
  --database-name "${MYSQL_DATABASE_NAME}" \
  --public-access None \
  --output table

echo "MySQL 서버 타임존 설정: +09:00"
az mysql flexible-server parameter set \
  --resource-group "${RESOURCE_GROUP}" \
  --server-name "${MYSQL_SERVER_NAME}" \
  --name time_zone \
  --value "+09:00" \
  --output table

if [[ -n "${DMS_CLIENT_IP}" ]]; then
  echo "AWS DMS 접속 IP 방화벽 허용: ${DMS_CLIENT_IP}"
  az mysql flexible-server firewall-rule create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${MYSQL_SERVER_NAME}" \
    --rule-name allow-aws-dms \
    --start-ip-address "${DMS_CLIENT_IP}" \
    --end-ip-address "${DMS_CLIENT_IP}" \
    --output table
else
  echo "DMS_CLIENT_IP가 없어 방화벽 규칙은 생성하지 않았습니다."
  echo "나중에 AWS DMS Replication Instance 공인 IP를 아래처럼 허용하세요:"
  echo "az mysql flexible-server firewall-rule create \\"
  echo "  --resource-group ${RESOURCE_GROUP} \\"
  echo "  --name ${MYSQL_SERVER_NAME} \\"
  echo "  --rule-name allow-aws-dms \\"
  echo "  --start-ip-address <AWS_DMS_PUBLIC_IP> \\"
  echo "  --end-ip-address <AWS_DMS_PUBLIC_IP>"
fi

echo
echo "생성 완료"
echo "Resource group : ${RESOURCE_GROUP}"
echo "Server name    : ${MYSQL_SERVER_NAME}"
echo "Database name  : ${MYSQL_DATABASE_NAME}"
echo "Admin user     : ${MYSQL_ADMIN_USER}"
echo "Host           : ${MYSQL_SERVER_NAME}.mysql.database.azure.com"
echo "JDBC URL       : jdbc:mysql://${MYSQL_SERVER_NAME}.mysql.database.azure.com:3306/${MYSQL_DATABASE_NAME}?useSSL=true&serverTimezone=Asia/Seoul"
