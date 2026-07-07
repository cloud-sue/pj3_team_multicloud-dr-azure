variable "namespace" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" { type = map(string) }
variable "gateway_subnet_id" { type = string } # network 모듈에서 받아옴

# AWS VPN apply 후 채울 값들
variable "aws_tunnel_ip" { type = string } # AWS VPN 터널 IP
variable "aws_vpc_cidr" { type = string }  # AWS VPC CIDR
variable "shared_key" {
  type      = string
  sensitive = true
}
