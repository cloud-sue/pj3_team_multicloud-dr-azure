locals {
  namespace = var.namespace

  vnet = {
    cidr_blocks = ["10.0.0.0/16"]
  }

  subnets = {
    mgmt = {
      name        = "snet-mgmt"
      cidr_blocks = ["10.0.0.0/24"]
      delegation  = null # delegation : 서브넷 위임 설정
    },
    appgw = {
      name        = "snet-appgw"
      cidr_blocks = ["10.0.1.0/24"]
      delegation  = null
    },
    aks = {
      name        = "snet-aks"
      cidr_blocks = ["10.0.16.0/20"]
      delegation  = null
    },
    pe = {
      name        = "snet-pe"
      cidr_blocks = ["10.0.3.0/24"]
      delegation  = null
    },
    mysql = {
      name        = "snet-mysql"
      cidr_blocks = ["10.0.4.0/24"]
      delegation = {
        name    = "delegation-${local.namespace}-mysql"                     # 위임 이름
        service = "Microsoft.DBforMySQL/flexibleServers"                    # 위임할 Azure 서비스
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"] # 허용 액션
      }
    },
    redis = {
      name        = "snet-redis"
      cidr_blocks = ["10.0.5.0/24"]
      delegation  = null
    },
    # Azure VPN Gateway는 반드시 "GatewaySubnet" 이름이어야 함 (Azure 강제 규칙)
    gateway = {
      name        = "GatewaySubnet"
      cidr_blocks = ["10.0.6.0/24"] # /27 이상 권장 (최소 /29)
      delegation  = null
    }

  }

  subnet_address_prefixes = {
    for key, subnet in local.subnets : key => subnet.cidr_blocks[0]
  }

  nsg_rules = {
    # RDP(3389)는 필요할 때 별도 규칙으로 추가합니다.
    mgmt = length(var.admin_source_address_prefixes) == 0 ? [] : [
      {
        name                         = "Allow-Admin-SSH"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "22"
        source_address_prefix        = null
        source_address_prefixes      = var.admin_source_address_prefixes
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      }
    ]

    appgw = [
      {
        name                         = "Allow-Internet-HTTP"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "80"
        source_address_prefix        = "Internet"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-Internet-HTTPS"
        priority                     = 110
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefix        = "Internet"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-GatewayManager" # Azure Application Gateway를 Azure가 관리하기 위해 접근하는 서비스 태그
        priority                     = 120
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "65200-65535"
        source_address_prefix        = "GatewayManager"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-AzureLoadBalancer"
        priority                     = 130
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "*"
        source_port_range            = "*"
        destination_port_range       = "*"
        source_address_prefix        = "AzureLoadBalancer"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-To-AKS-HTTP"
        priority                     = 200
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "80"
        source_address_prefix        = "*"
        source_address_prefixes      = null
        destination_address_prefix   = local.subnet_address_prefixes.aks
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-To-AKS-HTTPS"
        priority                     = 210
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefix        = "*"
        source_address_prefixes      = null
        destination_address_prefix   = local.subnet_address_prefixes.aks
        destination_address_prefixes = null
      }
    ]

    aks = [
      {
        name                         = "Allow-From-AppGW-HTTP"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "80"
        source_address_prefix        = local.subnet_address_prefixes.appgw
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-From-AppGW-HTTPS"
        priority                     = 110
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefix        = local.subnet_address_prefixes.appgw
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-To-MySQL"
        priority                     = 200
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "3306"
        source_address_prefix        = "*"
        source_address_prefixes      = null
        destination_address_prefix   = local.subnet_address_prefixes.mysql
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-To-Redis"
        priority                     = 210
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "10000"
        source_address_prefix        = "*"
        source_address_prefixes      = null
        destination_address_prefix   = local.subnet_address_prefixes.redis
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-To-PrivateEndpoint"
        priority                     = 220
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefix        = "*"
        source_address_prefixes      = null
        destination_address_prefix   = local.subnet_address_prefixes.pe
        destination_address_prefixes = null
      }
    ]

    mysql = [
      {
        name                         = "Allow-From-AKS-MySQL"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "3306"
        source_address_prefix        = local.subnet_address_prefixes.aks
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      },
      {
        name                         = "Allow-From-AWS-DMS"
        priority                     = 110
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "3306"
        source_address_prefix        = "192.0.0.0/16"
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      }
    ]

    pe = [
      {
        name                         = "Allow-From-AKS-HTTPS"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "443"
        source_address_prefix        = local.subnet_address_prefixes.aks
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      }
    ]

    redis = [
      {
        name                         = "Allow-From-AKS-Redis"
        priority                     = 100
        direction                    = "Inbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_range       = "10000"
        source_address_prefix        = local.subnet_address_prefixes.aks
        source_address_prefixes      = null
        destination_address_prefix   = "*"
        destination_address_prefixes = null
      }
    ]
  }

  nsg_rule_list = flatten([
    for subnet_key, rules in local.nsg_rules : [
      for rule in rules : merge(rule, {
        key        = "${subnet_key}-${rule.name}"
        subnet_key = subnet_key
      })
    ]
  ])
}
