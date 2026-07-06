#!/usr/bin/env bash
set -euo pipefail

# 목적:
#   AWS DMS 동기화 테스트용 VPC, 서브넷, 보안그룹, RDS DB subnet group,
#   DMS replication subnet group을 Terraform 상태와 분리해서 AWS CLI로 생성합니다.
#
# 생성 리소스:
#   - VPC
#   - Internet Gateway
#   - Public subnet 2개
#   - Public route table
#   - RDS MySQL 보안그룹
#   - DMS Replication Instance 보안그룹
#   - DMS VPC 관리용 IAM Role(dms-vpc-role)
#   - RDS DB subnet group
#   - DMS replication subnet group
#
# 사용 예:
#   ./script/create_aws_drtest_network.sh
#
# 생성 후 출력되는 export 값을 create_aws_mysql_drtest.sh 실행 시 사용하세요.

prompt_with_default() {
  local var_name="$1"
  local prompt_text="$2"
  local default_value="$3"
  local input_value

  read -r -p "${prompt_text} [${default_value}]: " input_value
  printf -v "${var_name}" '%s' "${input_value:-${default_value}}"
}

ensure_dms_vpc_role() {
  local role_name="dms-vpc-role"
  local policy_arn="arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
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
    echo "DMS IAM Role 확인됨: ${role_name}"
  else
    echo "DMS IAM Role 생성: ${role_name}"
    aws iam create-role \
      --role-name "${role_name}" \
      --assume-role-policy-document "${trust_policy}" \
      --description "Allows AWS DMS to manage VPC resources for replication" \
      --tags Key=Name,Value="${role_name}" Key=Purpose,Value=dms-drtest \
      --output table
  fi

  echo "DMS IAM Role policy 연결: AmazonDMSVPCManagementRole"
  aws iam attach-role-policy \
    --role-name "${role_name}" \
    --policy-arn "${policy_arn}"

  echo "IAM Role 반영 대기"
  sleep 10
}

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
NAME_PREFIX="${NAME_PREFIX:-drtest}"
VPC_CIDR="${VPC_CIDR:-10.70.0.0/16}"
PUBLIC_SUBNET_1_CIDR="${PUBLIC_SUBNET_1_CIDR:-10.70.1.0/24}"
PUBLIC_SUBNET_2_CIDR="${PUBLIC_SUBNET_2_CIDR:-10.70.2.0/24}"
RDS_DB_SUBNET_GROUP_NAME="${RDS_DB_SUBNET_GROUP_NAME:-}"
DMS_REPLICATION_SUBNET_GROUP_ID="${DMS_REPLICATION_SUBNET_GROUP_ID:-}"
ADMIN_CLIENT_CIDR="${ADMIN_CLIENT_CIDR:-}"

echo "AWS 계정 확인"
aws sts get-caller-identity --output table

prompt_with_default AWS_REGION "AWS Region" "${AWS_REGION}"
prompt_with_default NAME_PREFIX "리소스 이름 prefix" "${NAME_PREFIX}"
prompt_with_default VPC_CIDR "VPC CIDR" "${VPC_CIDR}"
prompt_with_default PUBLIC_SUBNET_1_CIDR "Public subnet 1 CIDR" "${PUBLIC_SUBNET_1_CIDR}"
prompt_with_default PUBLIC_SUBNET_2_CIDR "Public subnet 2 CIDR" "${PUBLIC_SUBNET_2_CIDR}"

if [[ -z "${RDS_DB_SUBNET_GROUP_NAME}" ]]; then
  RDS_DB_SUBNET_GROUP_NAME="${NAME_PREFIX}-mysql-subnet-group"
fi

if [[ -z "${DMS_REPLICATION_SUBNET_GROUP_ID}" ]]; then
  DMS_REPLICATION_SUBNET_GROUP_ID="${NAME_PREFIX}-dms-subnet-group"
fi

read -r -p "관리자 PC에서 RDS MySQL 3306 접속을 허용할 CIDR, 없으면 Enter: " ADMIN_CLIENT_CIDR

read -r AZ_1 AZ_2 <<< "$(aws ec2 describe-availability-zones \
  --region "${AWS_REGION}" \
  --filters Name=state,Values=available \
  --query 'AvailabilityZones[0:2].ZoneName' \
  --output text)"

if [[ -z "${AZ_1}" || -z "${AZ_2}" || "${AZ_2}" == "None" ]]; then
  echo "사용 가능한 AZ 2개를 찾지 못했습니다. Region을 확인하세요."
  exit 1
fi

echo "VPC 생성: ${NAME_PREFIX}-vpc (${VPC_CIDR})"
VPC_ID="$(aws ec2 create-vpc \
  --region "${AWS_REGION}" \
  --cidr-block "${VPC_CIDR}" \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${NAME_PREFIX}-vpc},{Key=Purpose,Value=dms-drtest}]" \
  --query 'Vpc.VpcId' \
  --output text)"

aws ec2 modify-vpc-attribute \
  --region "${AWS_REGION}" \
  --vpc-id "${VPC_ID}" \
  --enable-dns-support '{"Value":true}'

aws ec2 modify-vpc-attribute \
  --region "${AWS_REGION}" \
  --vpc-id "${VPC_ID}" \
  --enable-dns-hostnames '{"Value":true}'

echo "Internet Gateway 생성 및 연결"
IGW_ID="$(aws ec2 create-internet-gateway \
  --region "${AWS_REGION}" \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${NAME_PREFIX}-igw},{Key=Purpose,Value=dms-drtest}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)"

aws ec2 attach-internet-gateway \
  --region "${AWS_REGION}" \
  --internet-gateway-id "${IGW_ID}" \
  --vpc-id "${VPC_ID}"

echo "Public subnet 생성: ${AZ_1}, ${AZ_2}"
SUBNET_1_ID="$(aws ec2 create-subnet \
  --region "${AWS_REGION}" \
  --vpc-id "${VPC_ID}" \
  --cidr-block "${PUBLIC_SUBNET_1_CIDR}" \
  --availability-zone "${AZ_1}" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${NAME_PREFIX}-public-${AZ_1}},{Key=Purpose,Value=dms-drtest}]" \
  --query 'Subnet.SubnetId' \
  --output text)"

SUBNET_2_ID="$(aws ec2 create-subnet \
  --region "${AWS_REGION}" \
  --vpc-id "${VPC_ID}" \
  --cidr-block "${PUBLIC_SUBNET_2_CIDR}" \
  --availability-zone "${AZ_2}" \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${NAME_PREFIX}-public-${AZ_2}},{Key=Purpose,Value=dms-drtest}]" \
  --query 'Subnet.SubnetId' \
  --output text)"

aws ec2 modify-subnet-attribute \
  --region "${AWS_REGION}" \
  --subnet-id "${SUBNET_1_ID}" \
  --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
  --region "${AWS_REGION}" \
  --subnet-id "${SUBNET_2_ID}" \
  --map-public-ip-on-launch

echo "Public route table 생성 및 연결"
ROUTE_TABLE_ID="$(aws ec2 create-route-table \
  --region "${AWS_REGION}" \
  --vpc-id "${VPC_ID}" \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${NAME_PREFIX}-public-rt},{Key=Purpose,Value=dms-drtest}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)"

aws ec2 create-route \
  --region "${AWS_REGION}" \
  --route-table-id "${ROUTE_TABLE_ID}" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "${IGW_ID}" \
  --output table

aws ec2 associate-route-table \
  --region "${AWS_REGION}" \
  --route-table-id "${ROUTE_TABLE_ID}" \
  --subnet-id "${SUBNET_1_ID}" \
  --output table

aws ec2 associate-route-table \
  --region "${AWS_REGION}" \
  --route-table-id "${ROUTE_TABLE_ID}" \
  --subnet-id "${SUBNET_2_ID}" \
  --output table

echo "보안그룹 생성"
DMS_SECURITY_GROUP_ID="$(aws ec2 create-security-group \
  --region "${AWS_REGION}" \
  --group-name "${NAME_PREFIX}-dms-sg" \
  --description "DMS replication instance security group for DR test" \
  --vpc-id "${VPC_ID}" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${NAME_PREFIX}-dms-sg},{Key=Purpose,Value=dms-drtest}]" \
  --query 'GroupId' \
  --output text)"

RDS_SECURITY_GROUP_ID="$(aws ec2 create-security-group \
  --region "${AWS_REGION}" \
  --group-name "${NAME_PREFIX}-mysql-sg" \
  --description "RDS MySQL security group for DR test" \
  --vpc-id "${VPC_ID}" \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${NAME_PREFIX}-mysql-sg},{Key=Purpose,Value=dms-drtest}]" \
  --query 'GroupId' \
  --output text)"

echo "RDS MySQL 3306 inbound 허용: DMS SG -> RDS SG"
aws ec2 authorize-security-group-ingress \
  --region "${AWS_REGION}" \
  --group-id "${RDS_SECURITY_GROUP_ID}" \
  --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,UserIdGroupPairs=[{GroupId=${DMS_SECURITY_GROUP_ID},Description='DMS replication instance'}]" \
  --output table

if [[ -n "${ADMIN_CLIENT_CIDR}" ]]; then
  echo "관리자 CIDR MySQL 3306 inbound 허용: ${ADMIN_CLIENT_CIDR}"
  aws ec2 authorize-security-group-ingress \
    --region "${AWS_REGION}" \
    --group-id "${RDS_SECURITY_GROUP_ID}" \
    --ip-permissions "IpProtocol=tcp,FromPort=3306,ToPort=3306,IpRanges=[{CidrIp=${ADMIN_CLIENT_CIDR},Description='Admin MySQL client'}]" \
    --output table
fi

echo "RDS DB subnet group 생성: ${RDS_DB_SUBNET_GROUP_NAME}"
aws rds create-db-subnet-group \
  --region "${AWS_REGION}" \
  --db-subnet-group-name "${RDS_DB_SUBNET_GROUP_NAME}" \
  --db-subnet-group-description "DR test RDS MySQL subnet group" \
  --subnet-ids "${SUBNET_1_ID}" "${SUBNET_2_ID}" \
  --tags Key=Name,Value="${RDS_DB_SUBNET_GROUP_NAME}" Key=Purpose,Value=dms-drtest \
  --output table

ensure_dms_vpc_role

echo "DMS replication subnet group 생성: ${DMS_REPLICATION_SUBNET_GROUP_ID}"
aws dms create-replication-subnet-group \
  --region "${AWS_REGION}" \
  --replication-subnet-group-identifier "${DMS_REPLICATION_SUBNET_GROUP_ID}" \
  --replication-subnet-group-description "DR test DMS subnet group" \
  --subnet-ids "${SUBNET_1_ID}" "${SUBNET_2_ID}" \
  --tags Key=Name,Value="${DMS_REPLICATION_SUBNET_GROUP_ID}" Key=Purpose,Value=dms-drtest \
  --output table

echo
echo "생성 완료"
echo "AWS_REGION=${AWS_REGION}"
echo "VPC_ID=${VPC_ID}"
echo "PUBLIC_SUBNET_1_ID=${SUBNET_1_ID}"
echo "PUBLIC_SUBNET_2_ID=${SUBNET_2_ID}"
echo "RDS_SECURITY_GROUP_ID=${RDS_SECURITY_GROUP_ID}"
echo "DMS_SECURITY_GROUP_ID=${DMS_SECURITY_GROUP_ID}"
echo "RDS_DB_SUBNET_GROUP_NAME=${RDS_DB_SUBNET_GROUP_NAME}"
echo "DMS_REPLICATION_SUBNET_GROUP_ID=${DMS_REPLICATION_SUBNET_GROUP_ID}"
echo
echo "RDS 생성 시 사용 예:"
echo "AWS_REGION=${AWS_REGION} \\"
echo "DB_SUBNET_GROUP_NAME=${RDS_DB_SUBNET_GROUP_NAME} \\"
echo "VPC_SECURITY_GROUP_ID=${RDS_SECURITY_GROUP_ID} \\"
echo "./script/create_aws_mysql_drtest.sh"
echo
echo "DMS Replication Instance 생성 시에는 아래 값을 사용하세요:"
echo "replication-subnet-group-identifier: ${DMS_REPLICATION_SUBNET_GROUP_ID}"
echo "vpc-security-group-ids            : ${DMS_SECURITY_GROUP_ID}"
