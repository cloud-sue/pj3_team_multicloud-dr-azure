locals {
  acme_dns_resource_group_name = coalesce(var.acme_dns_resource_group_name, azurerm_resource_group.this.name)

  # ACME provider는 내부적으로 lego DNS provider를 사용합니다.
  # Azure DNS provider code는 "azuredns"이고, 아래 config 값으로 _acme-challenge TXT 레코드를 생성합니다.
  acme_azure_dns_challenge_config = merge(
    {
      AZURE_AUTH_METHOD         = var.acme_azure_auth_method
      AZURE_SUBSCRIPTION_ID     = var.subscription_id
      AZURE_TENANT_ID           = data.azurerm_client_config.current.tenant_id
      AZURE_RESOURCE_GROUP      = local.acme_dns_resource_group_name
      AZURE_ZONE_NAME           = var.acme_dns_zone_name
      AZURE_PRIVATE_ZONE        = "false"
      AZURE_TTL                 = tostring(var.acme_dns_txt_ttl)
      AZURE_PROPAGATION_TIMEOUT = tostring(var.acme_dns_propagation_timeout)
    },
    var.acme_azure_client_id != "" ? { AZURE_CLIENT_ID = var.acme_azure_client_id } : {},
    var.acme_azure_client_secret != "" ? { AZURE_CLIENT_SECRET = var.acme_azure_client_secret } : {},
  )

  # ACME 자동 발급을 켜면 직접 입력한 PFX 대신 ACME 결과물을 AppGW 모듈에 전달합니다.
  appgw_import_ssl_certificate     = var.enable_acme_certificate ? true : var.appgw_import_ssl_certificate
  appgw_ssl_certificate_secret_id  = var.enable_acme_certificate ? null : var.appgw_ssl_certificate_key_vault_secret_id
  appgw_ssl_certificate_pfx_base64 = var.enable_acme_certificate ? one(acme_certificate.web[*].certificate_p12) : var.appgw_ssl_certificate_pfx_base64
  appgw_ssl_certificate_password   = var.enable_acme_certificate ? var.acme_certificate_p12_password : var.appgw_ssl_certificate_password
}

# Let's Encrypt 계정입니다. account_key_pem은 Terraform state에 sensitive 값으로 저장됩니다.
resource "acme_registration" "letsencrypt" {
  count = var.enable_acme_certificate ? 1 : 0

  email_address = var.acme_email_address
}

# www.sue019522.shop 공인 인증서를 DNS-01 challenge로 발급합니다.
# Azure DNS Zone(sue019522.shop)에 _acme-challenge.www TXT 레코드를 임시로 만들고 검증 후 정리합니다.
resource "acme_certificate" "web" {
  count = var.enable_acme_certificate ? 1 : 0

  account_key_pem          = acme_registration.letsencrypt[0].account_key_pem
  common_name              = var.appgw_ssl_hostname
  certificate_p12_password = var.acme_certificate_p12_password
  key_type                 = "P256"
  min_days_remaining       = 30
  recursive_nameservers    = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = "azuredns"
    config   = local.acme_azure_dns_challenge_config
  }

  # DNS zone이 같은 apply에서 생성될 때 ACME challenge가 먼저 실행되지 않게 한다.
  depends_on = [module.dns]
}
