locals {
  namespace           = var.namespace
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id
  tags                = var.tags

  names = {
    application_gateway = "agw-${local.namespace}"
    identity            = "id-agw-${local.namespace}"
    key_vault           = "kv-agw-${local.namespace}"
    public_ip           = "pip-agw-${local.namespace}"
    waf_policy          = "waf-agw-${local.namespace}"
  }

  https = {
    enabled                  = var.enable_https
    hostname                 = var.ssl_hostname
    certificate_name         = var.ssl_certificate_name
    frontend_port_name       = "frontend-https"
    frontend_port            = 443
    placeholder_listener     = "agic-placeholder-https-listener"
    key_vault_sku_name       = "standard"
    secret_retention_days    = 7
    purge_protection_enabled = false
  }

  public_ip = {
    allocation_method = "Static"
    domain_name_label = "pip-agw-${local.namespace}"
    fqdn              = "pip-agw-${local.namespace}.${local.location}.cloudapp.azure.com"
    sku               = "Standard"
  }

  application_gateway = {
    zones = ["1", "2", "3"]

    sku = {
      name = "WAF_v2"
      tier = "WAF_v2"
    }

    autoscale = {
      min_capacity = 1
      max_capacity = 3
    }
  }

  gateway_ip_configuration = {
    name = "gateway-ip-config"
  }

  frontend_ip_configuration = {
    name = "frontend-public"
  }

  frontend_port = {
    name = "frontend-http"
    port = 80
  }

  backend_address_pool = {
    name = "agic-placeholder-backend"
  }

  backend_http_settings = {
    name     = "agic-placeholder-http"
    port     = 80
    protocol = "Http"
  }

  http_listener = {
    name     = "agic-placeholder-listener"
    protocol = "Http"
  }

  request_routing_rule = {
    name     = "agic-placeholder-rule"
    type     = "Basic"
    priority = 100
  }

  waf = {
    enabled          = true
    mode             = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  access_policies = {
    # Application Gateway는 User Assigned Managed Identity로 Key Vault의 certificate secret을 읽습니다.
    app_gateway_secret_permissions = ["Get"]

    # Terraform 실행 주체는 인증서 import 또는 refresh를 위해 certificate/secret 조회 권한이 필요합니다.
    terraform_certificate_permissions = ["Create", "Delete", "Get", "Import", "List", "ManageContacts", "Purge", "Recover", "Update"]
    terraform_secret_permissions      = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }
}
