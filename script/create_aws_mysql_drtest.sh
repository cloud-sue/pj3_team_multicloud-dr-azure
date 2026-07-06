#!/usr/bin/env bash
set -euo pipefail

# 목적:
#   AWS DMS 동기화 테스트용 Amazon RDS MySQL DB를
#   Terraform 상태와 분리해서 AWS CLI로 생성합니다.
#
# 기본값:
#   Region      : ap-northeast-2
#   DB instance : drtest-mysql-${RANDOM}
#   DB name     : kbeauty
#
# 사용 예:
#   ./script/create_aws_mysql_drtest.sh
#
# DMS Replication Instance가 접근할 CIDR을 알고 있으면 보안그룹 inbound를 함께 엽니다.
#   DMS_CLIENT_CIDR=10.0.1.25/32 ./script/create_aws_mysql_drtest.sh
#
# 이미 사용할 DB subnet group 또는 VPC security group이 있으면 환경변수로 지정하세요.
#   DB_SUBNET_GROUP_NAME=my-db-subnet-group \
#   VPC_SECURITY_GROUP_ID=sg-0123456789abcdef0 \
#   ./script/create_aws_mysql_drtest.sh

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
DB_INSTANCE_IDENTIFIER="${DB_INSTANCE_IDENTIFIER:-azsis-drtest-${RANDOM}}"
DB_NAME="${DB_NAME:-kbeauty}"
DB_USERNAME="${DB_USERNAME:-testuser}"
DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.micro}"
ALLOCATED_STORAGE_GB="${ALLOCATED_STORAGE_GB:-20}"
STORAGE_TYPE="${STORAGE_TYPE:-gp3}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-1}"
DB_SUBNET_GROUP_NAME="${DB_SUBNET_GROUP_NAME:-}"
VPC_SECURITY_GROUP_ID="${VPC_SECURITY_GROUP_ID:-}"
DMS_CLIENT_CIDR="${DMS_CLIENT_CIDR:-}"
PUBLICLY_ACCESSIBLE="${PUBLICLY_ACCESSIBLE:-false}"
DELETION_PROTECTION="${DELETION_PROTECTION:-false}"
SG_NAME="${SG_NAME:-drtest-mysql-sg}"

echo "AWS 계정 확인"
aws sts get-caller-identity --output table

read -r -s -p "RDS MySQL 관리자 비밀번호를 입력하세요: " DB_PASSWORD
echo

if [[ -z "${DB_PASSWORD}" ]]; then
  echo "비밀번호가 비어 있습니다. 중단합니다."
  exit 1
fi

security_group_args=()
if [[ -n "${VPC_SECURITY_GROUP_ID}" ]]; then
  security_group_args+=(--vpc-security-group-ids "${VPC_SECURITY_GROUP_ID}")
elif [[ -n "${DMS_CLIENT_CIDR}" ]]; then
  echo "기본 VPC 확인"
  default_vpc_id="$(aws ec2 describe-vpcs \
    --region "${AWS_REGION}" \
    --filters Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)"

  if [[ -z "${default_vpc_id}" || "${default_vpc_id}" == "None" ]]; then
    echo "기본 VPC를 찾지 못했습니다."
    echo "VPC_SECURITY_GROUP_ID 또는 DB_SUBNET_GROUP_NAME을 지정해서 다시 실행하세요."
    exit 1
  fi

  echo "DMS 테스트용 보안그룹 생성 또는 확인: ${SG_NAME}"
  existing_sg_id="$(aws ec2 describe-security-groups \
    --region "${AWS_REGION}" \
    --filters Name=vpc-id,Values="${default_vpc_id}" Name=group-name,Values="${SG_NAME}" \
    --query 'SecurityGroups[0].GroupId' \
    --output text)"

  if [[ -z "${existing_sg_id}" || "${existing_sg_id}" == "None" ]]; then
    VPC_SECURITY_GROUP_ID="$(aws ec2 create-security-group \
      --region "${AWS_REGION}" \
      --group-name "${SG_NAME}" \
      --description "AWS DMS test access to RDS MySQL" \
      --vpc-id "${default_vpc_id}" \
      --query 'GroupId' \
      --output text)"
  else
    VPC_SECURITY_GROUP_ID="${existing_sg_id}"
  fi

  echo "MySQL 3306 inbound 허용: ${DMS_CLIENT_CIDR}"
  aws ec2 authorize-security-group-ingress \
    --region "${AWS_REGION}" \
    --group-id "${VPC_SECURITY_GROUP_ID}" \
    --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,IpRanges=[{CidrIp=${DMS_CLIENT_CIDR},Description='AWS DMS MySQL test'}]" \
    --output table || true

  security_group_args+=(--vpc-security-group-ids "${VPC_SECURITY_GROUP_ID}")
fi

subnet_group_args=()
if [[ -n "${DB_SUBNET_GROUP_NAME}" ]]; then
  subnet_group_args+=(--db-subnet-group-name "${DB_SUBNET_GROUP_NAME}")
fi

public_access_args=(--no-publicly-accessible)
if [[ "${PUBLICLY_ACCESSIBLE}" == "true" ]]; then
  public_access_args=(--publicly-accessible)
fi

deletion_protection_args=(--no-deletion-protection)
if [[ "${DELETION_PROTECTION}" == "true" ]]; then
  deletion_protection_args=(--deletion-protection)
fi

if [[ ${#security_group_args[@]} -eq 0 ]]; then
  echo "별도 보안그룹을 지정하지 않았습니다."
  echo "DMS가 다른 보안그룹 또는 CIDR에서 접근한다면 DMS_CLIENT_CIDR 또는 VPC_SECURITY_GROUP_ID를 지정하세요."
fi

echo "RDS MySQL DB 인스턴스 생성: ${DB_INSTANCE_IDENTIFIER}"
aws rds create-db-instance \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
  --engine mysql \
  --db-instance-class "${DB_INSTANCE_CLASS}" \
  --allocated-storage "${ALLOCATED_STORAGE_GB}" \
  --storage-type "${STORAGE_TYPE}" \
  --db-name "${DB_NAME}" \
  --master-username "${DB_USERNAME}" \
  --master-user-password "${DB_PASSWORD}" \
  --backup-retention-period "${BACKUP_RETENTION_DAYS}" \
  --no-multi-az \
  --no-auto-minor-version-upgrade \
  "${deletion_protection_args[@]}" \
  "${public_access_args[@]}" \
  "${security_group_args[@]}" \
  "${subnet_group_args[@]}" \
  --tags Key=Name,Value="${DB_INSTANCE_IDENTIFIER}" Key=Purpose,Value=dms-drtest \
  --output table

echo "DB 인스턴스가 available 상태가 될 때까지 대기합니다."
aws rds wait db-instance-available \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}"

endpoint="$(aws rds describe-db-instances \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)"

port="$(aws rds describe-db-instances \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
  --query 'DBInstances[0].Endpoint.Port' \
  --output text)"

echo
echo "생성 완료"
echo "Region        : ${AWS_REGION}"
echo "DB instance   : ${DB_INSTANCE_IDENTIFIER}"
echo "Database name : ${DB_NAME}"
echo "Admin user    : ${DB_USERNAME}"
echo "Endpoint      : ${endpoint}"
echo "Port          : ${port}"
echo "JDBC URL      : jdbc:mysql://${endpoint}:${port}/${DB_NAME}?useSSL=true&serverTimezone=Asia/Seoul"
