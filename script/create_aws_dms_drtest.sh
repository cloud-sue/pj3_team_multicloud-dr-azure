#!/usr/bin/env bash
set -euo pipefail

# 목적:
#   AWS DMS 동기화 테스트용 Replication Instance를 생성하고,
#   선택적으로 MySQL source/target endpoint와 replication task까지 생성합니다.
#
# 사전 준비:
#   ./script/create_aws_drtest_network.sh 실행 후 출력된 값을 사용하세요.
#
# 사용 예:
#   AWS_REGION=ap-northeast-2 \
#   DMS_REPLICATION_SUBNET_GROUP_ID=drtest-dms-subnet-group \
#   DMS_SECURITY_GROUP_ID=sg-0123456789abcdef0 \
#   ./script/create_aws_dms_drtest.sh

export AWS_PAGER="${AWS_PAGER:-}"

prompt_with_default() {
  local var_name="$1"
  local prompt_text="$2"
  local default_value="$3"
  local input_value

  read -r -p "${prompt_text} [${default_value}]: " input_value
  printf -v "${var_name}" '%s' "${input_value:-${default_value}}"
}

prompt_secret() {
  local var_name="$1"
  local prompt_text="$2"
  local input_value

  read -r -s -p "${prompt_text}: " input_value
  echo
  printf -v "${var_name}" '%s' "${input_value}"
}

confirm_yes() {
  local prompt_text="$1"
  local answer

  read -r -p "${prompt_text} [y/N] " answer
  case "${answer}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_iam_role() {
  local role_name="$1"
  local policy_arn="$2"
  local description="$3"
  local trust_policy

  trust_policy='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "dms.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

  if aws iam get-role --role-name "${role_name}" --output text >/dev/null 2>&1; then
    echo "IAM Role 확인됨: ${role_name}"
  else
    echo "IAM Role 생성: ${role_name}"
    aws iam create-role \
      --role-name "${role_name}" \
      --assume-role-policy-document "${trust_policy}" \
      --description "${description}" \
      --tags Key=Name,Value="${role_name}" Key=Purpose,Value=dms-drtest \
      --output table
  fi

  echo "IAM Role policy 연결: ${policy_arn}"
  aws iam attach-role-policy \
    --role-name "${role_name}" \
    --policy-arn "${policy_arn}"
}

create_mysql_endpoint() {
  local endpoint_identifier="$1"
  local endpoint_type="$2"
  local server_name="$3"
  local port="$4"
  local database_name="$5"
  local username="$6"
  local password="$7"
  local ssl_mode="$8"

  aws dms create-endpoint \
    --region "${AWS_REGION}" \
    --endpoint-identifier "${endpoint_identifier}" \
    --endpoint-type "${endpoint_type}" \
    --engine-name mysql \
    --server-name "${server_name}" \
    --port "${port}" \
    --database-name "${database_name}" \
    --username "${username}" \
    --password "${password}" \
    --ssl-mode "${ssl_mode}" \
    --tags Key=Name,Value="${endpoint_identifier}" Key=Purpose,Value=dms-drtest \
    --query 'Endpoint.EndpointArn' \
    --output text
}

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
NAME_PREFIX="${NAME_PREFIX:-drtest}"
DMS_REPLICATION_INSTANCE_ID="${DMS_REPLICATION_INSTANCE_ID:-${NAME_PREFIX}-dms-${RANDOM}}"
DMS_REPLICATION_INSTANCE_CLASS="${DMS_REPLICATION_INSTANCE_CLASS:-dms.t3.micro}"
DMS_ALLOCATED_STORAGE_GB="${DMS_ALLOCATED_STORAGE_GB:-20}"
DMS_REPLICATION_SUBNET_GROUP_ID="${DMS_REPLICATION_SUBNET_GROUP_ID:-${NAME_PREFIX}-dms-subnet-group}"
DMS_SECURITY_GROUP_ID="${DMS_SECURITY_GROUP_ID:-}"
DMS_PUBLICLY_ACCESSIBLE="${DMS_PUBLICLY_ACCESSIBLE:-true}"

echo "AWS 계정 확인"
aws sts get-caller-identity --output table

prompt_with_default AWS_REGION "AWS Region" "${AWS_REGION}"
prompt_with_default NAME_PREFIX "리소스 이름 prefix" "${NAME_PREFIX}"
prompt_with_default DMS_REPLICATION_INSTANCE_ID "DMS Replication Instance ID" "${DMS_REPLICATION_INSTANCE_ID}"
prompt_with_default DMS_REPLICATION_INSTANCE_CLASS "DMS Instance class" "${DMS_REPLICATION_INSTANCE_CLASS}"
prompt_with_default DMS_ALLOCATED_STORAGE_GB "DMS storage GB" "${DMS_ALLOCATED_STORAGE_GB}"
prompt_with_default DMS_REPLICATION_SUBNET_GROUP_ID "DMS replication subnet group ID" "${DMS_REPLICATION_SUBNET_GROUP_ID}"
prompt_with_default DMS_SECURITY_GROUP_ID "DMS security group ID" "${DMS_SECURITY_GROUP_ID}"
prompt_with_default DMS_PUBLICLY_ACCESSIBLE "DMS public IP 사용 true/false" "${DMS_PUBLICLY_ACCESSIBLE}"

ensure_iam_role \
  "dms-vpc-role" \
  "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole" \
  "Allows AWS DMS to manage VPC resources for replication"

ensure_iam_role \
  "dms-cloudwatch-logs-role" \
  "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole" \
  "Allows AWS DMS to write task logs to CloudWatch"

echo "IAM Role 반영 대기"
sleep 10

security_group_args=()
if [[ -n "${DMS_SECURITY_GROUP_ID}" ]]; then
  security_group_args+=(--vpc-security-group-ids "${DMS_SECURITY_GROUP_ID}")
fi

public_access_args=(--publicly-accessible)
if [[ "${DMS_PUBLICLY_ACCESSIBLE}" == "false" ]]; then
  public_access_args=(--no-publicly-accessible)
fi

echo "DMS Replication Instance 생성: ${DMS_REPLICATION_INSTANCE_ID}"
aws dms create-replication-instance \
  --region "${AWS_REGION}" \
  --replication-instance-identifier "${DMS_REPLICATION_INSTANCE_ID}" \
  --replication-instance-class "${DMS_REPLICATION_INSTANCE_CLASS}" \
  --allocated-storage "${DMS_ALLOCATED_STORAGE_GB}" \
  --replication-subnet-group-identifier "${DMS_REPLICATION_SUBNET_GROUP_ID}" \
  --no-multi-az \
  --no-auto-minor-version-upgrade \
  "${public_access_args[@]}" \
  "${security_group_args[@]}" \
  --tags Key=Name,Value="${DMS_REPLICATION_INSTANCE_ID}" Key=Purpose,Value=dms-drtest \
  --output table

echo "DMS Replication Instance가 available 상태가 될 때까지 대기합니다."
aws dms wait replication-instance-available \
  --region "${AWS_REGION}" \
  --filters "Name=replication-instance-id,Values=${DMS_REPLICATION_INSTANCE_ID}"

DMS_REPLICATION_INSTANCE_ARN="$(aws dms describe-replication-instances \
  --region "${AWS_REGION}" \
  --filters "Name=replication-instance-id,Values=${DMS_REPLICATION_INSTANCE_ID}" \
  --query 'ReplicationInstances[0].ReplicationInstanceArn' \
  --output text)"

DMS_PUBLIC_IP="$(aws dms describe-replication-instances \
  --region "${AWS_REGION}" \
  --filters "Name=replication-instance-id,Values=${DMS_REPLICATION_INSTANCE_ID}" \
  --query 'ReplicationInstances[0].ReplicationInstancePublicIpAddress' \
  --output text)"

DMS_PRIVATE_IP="$(aws dms describe-replication-instances \
  --region "${AWS_REGION}" \
  --filters "Name=replication-instance-id,Values=${DMS_REPLICATION_INSTANCE_ID}" \
  --query 'ReplicationInstances[0].ReplicationInstancePrivateIpAddress' \
  --output text)"

SOURCE_ENDPOINT_ARN=""
TARGET_ENDPOINT_ARN=""
REPLICATION_TASK_ARN=""

if confirm_yes "MySQL source/target endpoint도 생성할까요?"; then
  SOURCE_ENDPOINT_ID="${SOURCE_ENDPOINT_ID:-${NAME_PREFIX}-source-mysql}"
  SOURCE_PORT="${SOURCE_PORT:-3306}"
  SOURCE_DATABASE_NAME="${SOURCE_DATABASE_NAME:-kbeauty}"
  SOURCE_USERNAME="${SOURCE_USERNAME:-testuser}"
  SOURCE_SSL_MODE="${SOURCE_SSL_MODE:-none}"

  TARGET_ENDPOINT_ID="${TARGET_ENDPOINT_ID:-${NAME_PREFIX}-target-mysql}"
  TARGET_PORT="${TARGET_PORT:-3306}"
  TARGET_DATABASE_NAME="${TARGET_DATABASE_NAME:-kbeauty}"
  TARGET_USERNAME="${TARGET_USERNAME:-testuser}"
  TARGET_SSL_MODE="${TARGET_SSL_MODE:-require}"

  echo "Source MySQL endpoint 정보"
  prompt_with_default SOURCE_ENDPOINT_ID "Source endpoint ID" "${SOURCE_ENDPOINT_ID}"
  prompt_with_default SOURCE_SERVER_NAME "Source MySQL host" "${SOURCE_SERVER_NAME:-}"
  prompt_with_default SOURCE_PORT "Source MySQL port" "${SOURCE_PORT}"
  prompt_with_default SOURCE_DATABASE_NAME "Source database name" "${SOURCE_DATABASE_NAME}"
  prompt_with_default SOURCE_USERNAME "Source username" "${SOURCE_USERNAME}"
  prompt_with_default SOURCE_SSL_MODE "Source SSL mode(none/require/verify-ca/verify-full)" "${SOURCE_SSL_MODE}"
  prompt_secret SOURCE_PASSWORD "Source password"

  echo "Target MySQL endpoint 정보"
  prompt_with_default TARGET_ENDPOINT_ID "Target endpoint ID" "${TARGET_ENDPOINT_ID}"
  prompt_with_default TARGET_SERVER_NAME "Target MySQL host" "${TARGET_SERVER_NAME:-}"
  prompt_with_default TARGET_PORT "Target MySQL port" "${TARGET_PORT}"
  prompt_with_default TARGET_DATABASE_NAME "Target database name" "${TARGET_DATABASE_NAME}"
  prompt_with_default TARGET_USERNAME "Target username" "${TARGET_USERNAME}"
  prompt_with_default TARGET_SSL_MODE "Target SSL mode(none/require/verify-ca/verify-full)" "${TARGET_SSL_MODE}"
  prompt_secret TARGET_PASSWORD "Target password"

  echo "Source endpoint 생성: ${SOURCE_ENDPOINT_ID}"
  SOURCE_ENDPOINT_ARN="$(create_mysql_endpoint \
    "${SOURCE_ENDPOINT_ID}" \
    "source" \
    "${SOURCE_SERVER_NAME}" \
    "${SOURCE_PORT}" \
    "${SOURCE_DATABASE_NAME}" \
    "${SOURCE_USERNAME}" \
    "${SOURCE_PASSWORD}" \
    "${SOURCE_SSL_MODE}")"

  echo "Target endpoint 생성: ${TARGET_ENDPOINT_ID}"
  TARGET_ENDPOINT_ARN="$(create_mysql_endpoint \
    "${TARGET_ENDPOINT_ID}" \
    "target" \
    "${TARGET_SERVER_NAME}" \
    "${TARGET_PORT}" \
    "${TARGET_DATABASE_NAME}" \
    "${TARGET_USERNAME}" \
    "${TARGET_PASSWORD}" \
    "${TARGET_SSL_MODE}")"

  if confirm_yes "endpoint 연결 테스트를 실행할까요?"; then
    echo "Source endpoint 연결 테스트"
    aws dms test-connection \
      --region "${AWS_REGION}" \
      --replication-instance-arn "${DMS_REPLICATION_INSTANCE_ARN}" \
      --endpoint-arn "${SOURCE_ENDPOINT_ARN}" \
      --output table

    echo "Target endpoint 연결 테스트"
    aws dms test-connection \
      --region "${AWS_REGION}" \
      --replication-instance-arn "${DMS_REPLICATION_INSTANCE_ARN}" \
      --endpoint-arn "${TARGET_ENDPOINT_ARN}" \
      --output table
  fi

  if confirm_yes "DMS replication task도 생성할까요?"; then
    REPLICATION_TASK_ID="${REPLICATION_TASK_ID:-${NAME_PREFIX}-mysql-task}"
    MIGRATION_TYPE="${MIGRATION_TYPE:-full-load}"
    TABLE_SCHEMA_NAME="${TABLE_SCHEMA_NAME:-${SOURCE_DATABASE_NAME}}"
    TABLE_NAME_PATTERN="${TABLE_NAME_PATTERN:-%}"

    prompt_with_default REPLICATION_TASK_ID "Replication task ID" "${REPLICATION_TASK_ID}"
    prompt_with_default MIGRATION_TYPE "Migration type(full-load/cdc/full-load-and-cdc)" "${MIGRATION_TYPE}"
    prompt_with_default TABLE_SCHEMA_NAME "복제할 schema/database 이름" "${TABLE_SCHEMA_NAME}"
    prompt_with_default TABLE_NAME_PATTERN "복제할 table 패턴" "${TABLE_NAME_PATTERN}"

    TABLE_MAPPINGS_FILE="/tmp/${REPLICATION_TASK_ID}-table-mappings.json"
    cat > "${TABLE_MAPPINGS_FILE}" <<EOF
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "include-${TABLE_SCHEMA_NAME}",
      "object-locator": {
        "schema-name": "${TABLE_SCHEMA_NAME}",
        "table-name": "${TABLE_NAME_PATTERN}"
      },
      "rule-action": "include",
      "filters": []
    }
  ]
}
EOF

    echo "Replication task 생성: ${REPLICATION_TASK_ID}"
    REPLICATION_TASK_ARN="$(aws dms create-replication-task \
      --region "${AWS_REGION}" \
      --replication-task-identifier "${REPLICATION_TASK_ID}" \
      --source-endpoint-arn "${SOURCE_ENDPOINT_ARN}" \
      --target-endpoint-arn "${TARGET_ENDPOINT_ARN}" \
      --replication-instance-arn "${DMS_REPLICATION_INSTANCE_ARN}" \
      --migration-type "${MIGRATION_TYPE}" \
      --table-mappings "file://${TABLE_MAPPINGS_FILE}" \
      --tags Key=Name,Value="${REPLICATION_TASK_ID}" Key=Purpose,Value=dms-drtest \
      --query 'ReplicationTask.ReplicationTaskArn' \
      --output text)"

    echo "Replication task가 ready 상태가 될 때까지 대기합니다."
    aws dms wait replication-task-ready \
      --region "${AWS_REGION}" \
      --filters "Name=replication-task-arn,Values=${REPLICATION_TASK_ARN}"

    if confirm_yes "Replication task를 바로 시작할까요?"; then
      aws dms start-replication-task \
        --region "${AWS_REGION}" \
        --replication-task-arn "${REPLICATION_TASK_ARN}" \
        --start-replication-task-type start-replication \
        --output table
    fi
  fi
fi

echo
echo "생성 완료"
echo "AWS_REGION=${AWS_REGION}"
echo "DMS_REPLICATION_INSTANCE_ID=${DMS_REPLICATION_INSTANCE_ID}"
echo "DMS_REPLICATION_INSTANCE_ARN=${DMS_REPLICATION_INSTANCE_ARN}"
echo "DMS_PUBLIC_IP=${DMS_PUBLIC_IP}"
echo "DMS_PRIVATE_IP=${DMS_PRIVATE_IP}"

if [[ -n "${SOURCE_ENDPOINT_ARN}" ]]; then
  echo "SOURCE_ENDPOINT_ARN=${SOURCE_ENDPOINT_ARN}"
fi

if [[ -n "${TARGET_ENDPOINT_ARN}" ]]; then
  echo "TARGET_ENDPOINT_ARN=${TARGET_ENDPOINT_ARN}"
fi

if [[ -n "${REPLICATION_TASK_ARN}" ]]; then
  echo "REPLICATION_TASK_ARN=${REPLICATION_TASK_ARN}"
fi

if [[ -n "${DMS_PUBLIC_IP}" && "${DMS_PUBLIC_IP}" != "None" ]]; then
  echo
  echo "Azure MySQL 방화벽 허용 예:"
  echo "DMS_CLIENT_IP=${DMS_PUBLIC_IP} ./script/create_azure_mysql_drtest.sh"
  echo "또는 기존 Azure MySQL이면:"
  echo "az mysql flexible-server firewall-rule create \\"
  echo "  --resource-group rg-drtest \\"
  echo "  --name <AZURE_MYSQL_SERVER_NAME> \\"
  echo "  --rule-name allow-aws-dms \\"
  echo "  --start-ip-address ${DMS_PUBLIC_IP} \\"
  echo "  --end-ip-address ${DMS_PUBLIC_IP}"
fi
