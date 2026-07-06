resource "azurerm_public_ip" "this" {
  name                = local.names.public_ip
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = local.public_ip.allocation_method
  domain_name_label   = local.public_ip.domain_name_label
  sku                 = local.public_ip.sku
  zones               = local.application_gateway.zones
  tags                = local.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = local.names.waf_policy
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = local.tags

  custom_rules {
    name      = "AllowHealthEndpoint"
    priority  = 1
    rule_type = "MatchRule"
    action    = "Allow"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }
      operator           = "BeginsWith"
      negation_condition = false
      match_values       = ["/health"]
    }
  }


  policy_settings {
    enabled = local.waf.enabled
    mode    = local.waf.mode
  }

  managed_rules {
    managed_rule_set {
      type    = local.waf.rule_set_type
      version = local.waf.rule_set_version
    }
  }
}

# 인증서  관련
# Application Gateway가 Key Vault 인증서를 읽을 때 사용할 전용 User Assigned Managed Identity입니다.
resource "azurerm_user_assigned_identity" "appgw" {
  count = local.https.enabled ? 1 : 0

  name                = local.names.identity
  resource_group_name = local.resource_group_name
  location            = local.location
  tags                = local.tags
}

# AppGW TLS 인증서를 보관하는 전용 Key Vault입니다.
# 운영 비밀용 Key Vault와 분리해 인증서 접근 권한을 최소화합니다.
resource "azurerm_key_vault" "appgw" {
  count = local.https.enabled ? 1 : 0

  name                       = local.names.key_vault
  resource_group_name        = local.resource_group_name
  location                   = local.location
  tenant_id                  = var.tenant_id
  sku_name                   = local.https.key_vault_sku_name
  soft_delete_retention_days = local.https.secret_retention_days
  purge_protection_enabled   = local.https.purge_protection_enabled
  tags                       = local.tags
}

# Key Vault의 CertificateNearExpiry 이벤트를 이메일로 받기 위한 연락처입니다.
# 인증서 policy의 lifetime_action과 함께 사용되며, 수신자 주소는 루트 변수로 관리합니다.
resource "azurerm_key_vault_certificate_contacts" "expiry_alert" {
  count = local.https.enabled && var.enable_certificate_expiry_alert ? 1 : 0

  key_vault_id = azurerm_key_vault.appgw[0].id

  dynamic "contact" {
    for_each = toset(var.certificate_expiry_alert_emails)
    content {
      email = contact.value
    }
  }

  depends_on = [azurerm_key_vault_access_policy.terraform]
}

# Terraform 실행 주체가 PFX 인증서를 Key Vault에 import하고 상태를 refresh할 수 있게 합니다.
resource "azurerm_key_vault_access_policy" "terraform" {
  for_each = local.https.enabled ? toset(var.certificate_admin_object_ids) : toset([])

  key_vault_id = azurerm_key_vault.appgw[0].id
  tenant_id    = var.tenant_id
  object_id    = each.value

  certificate_permissions = local.access_policies.terraform_certificate_permissions
  secret_permissions      = local.access_policies.terraform_secret_permissions
}

# Application Gateway에는 인증서 secret을 읽는 최소 권한만 부여합니다.
resource "azurerm_key_vault_access_policy" "appgw" {
  count = local.https.enabled ? 1 : 0

  key_vault_id = azurerm_key_vault.appgw[0].id
  tenant_id    = var.tenant_id
  object_id    = azurerm_user_assigned_identity.appgw[0].principal_id

  secret_permissions = local.access_policies.app_gateway_secret_permissions
}

# import_ssl_certificate=true일 때 Terraform 변수로 받은 PFX를 Key Vault certificate로 등록합니다.
# 이미 별도로 업로드한 인증서가 있으면 ssl_certificate_key_vault_secret_id만 넘기고 이 리소스는 만들지 않습니다.
resource "azurerm_key_vault_certificate" "ssl" {
  count = local.https.enabled && var.import_ssl_certificate ? 1 : 0

  name         = local.https.certificate_name
  key_vault_id = azurerm_key_vault.appgw[0].id

  certificate {
    contents = var.ssl_certificate_pfx_base64
    password = var.ssl_certificate_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Unknown"
    }

    key_properties {
      exportable = true
      curve      = "P-256"
      key_type   = "EC"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    # Azure Key Vault가 CertificateNearExpiry 이벤트를 생성해 위 contact로 안내 메일을 보냅니다.
    lifetime_action {
      action {
        action_type = "EmailContacts"
      }

      trigger {
        days_before_expiry = var.certificate_expiry_alert_days
      }
    }
  }

  depends_on = [
    azurerm_key_vault_access_policy.terraform,
    azurerm_key_vault_certificate_contacts.expiry_alert,
  ]
}

resource "azurerm_application_gateway" "this" {
  name                = local.names.application_gateway
  resource_group_name = local.resource_group_name
  location            = local.location
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id
  zones               = local.application_gateway.zones
  tags                = local.tags

  dynamic "identity" {
    for_each = local.https.enabled ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.appgw[0].id]
    }
  }

  sku {
    name = local.application_gateway.sku.name
    tier = local.application_gateway.sku.tier
  }

  autoscale_configuration {
    min_capacity = local.application_gateway.autoscale.min_capacity
    max_capacity = local.application_gateway.autoscale.max_capacity
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration.name
    subnet_id = local.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration.name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = local.frontend_port.name
    port = local.frontend_port.port
  }

  # AGIC가 HTTPS Ingress annotation을 읽으면 이 443 frontend port를 사용해 listener를 구성합니다.
  dynamic "frontend_port" {
    for_each = local.https.enabled ? [1] : []
    content {
      name = local.https.frontend_port_name
      port = local.https.frontend_port
    }
  }

  backend_address_pool {
    name = local.backend_address_pool.name
  }

  backend_http_settings {
    name                  = local.backend_http_settings.name
    cookie_based_affinity = "Disabled"
    port                  = local.backend_http_settings.port
    protocol              = local.backend_http_settings.protocol
  }

  http_listener {
    name                           = local.http_listener.name
    frontend_ip_configuration_name = local.frontend_ip_configuration.name
    frontend_port_name             = local.frontend_port.name
    protocol                       = local.http_listener.protocol
  }

  # Terraform이 인증서를 AppGW에 등록해두면 AGIC Ingress annotation이 같은 이름을 참조해 HTTPS listener를 만듭니다.
  dynamic "ssl_certificate" {
    for_each = local.https.enabled ? [1] : []
    content {
      name                = local.https.certificate_name
      key_vault_secret_id = try(coalesce(var.ssl_certificate_key_vault_secret_id, try(azurerm_key_vault_certificate.ssl[0].secret_id, null)), null)
    }
  }

  # 최초 생성 시 AppGW 스키마 요구사항을 만족시키는 placeholder HTTPS listener입니다.
  # 실제 host/path 라우팅은 Kubernetes Ingress를 보고 AGIC가 갱신합니다.
  dynamic "http_listener" {
    for_each = local.https.enabled ? [1] : []
    content {
      name                           = local.https.placeholder_listener
      frontend_ip_configuration_name = local.frontend_ip_configuration.name
      frontend_port_name             = local.https.frontend_port_name
      protocol                       = "Https"
      host_name                      = local.https.hostname
      ssl_certificate_name           = local.https.certificate_name
    }
  }

  request_routing_rule {
    name                       = local.request_routing_rule.name
    rule_type                  = local.request_routing_rule.type
    http_listener_name         = local.http_listener.name
    backend_address_pool_name  = local.backend_address_pool.name
    backend_http_settings_name = local.backend_http_settings.name
    priority                   = local.request_routing_rule.priority
  }

  # AGIC가 App Gateway 라우팅 설정을 바꿔도 
  # Terraform이 다시 덮어쓰지 않도록 ignore_changes 추가
  lifecycle {
    precondition {
      condition     = !local.https.enabled || var.import_ssl_certificate || var.ssl_certificate_key_vault_secret_id != null
      error_message = "enable_https=true이면 import_ssl_certificate=true로 PFX를 import하거나 ssl_certificate_key_vault_secret_id를 지정해야 합니다."
    }

    ignore_changes = [
      frontend_port,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule,
      rewrite_rule_set,
      ssl_certificate,
      trusted_root_certificate,
      url_path_map,
    ]
  }

  depends_on = [
    azurerm_key_vault_access_policy.appgw,
    azurerm_key_vault_certificate.ssl,
  ]
}
