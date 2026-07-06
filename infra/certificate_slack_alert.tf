locals {
  certificate_slack_alert_enabled = var.enable_certificate_slack_alert && try(length(trimspace(var.slack_webhook_url)), 0) > 0
  certificate_slack_function_name = "certificateExpirySlackAlert"
}

# Function App 실행에 필요한 저장소와 Consumption Plan입니다.
resource "azurerm_storage_account" "certificate_slack_alert" {
  count = local.certificate_slack_alert_enabled ? 1 : 0

  name                     = "certalert${substr(md5(azurerm_resource_group.this.id), 0, 8)}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.common_tags
}

resource "azurerm_service_plan" "certificate_slack_alert" {
  count = local.certificate_slack_alert_enabled ? 1 : 0

  name                = "asp-${local.namespace}-certalert"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.common_tags
}

data "archive_file" "certificate_slack_alert" {
  count = local.certificate_slack_alert_enabled ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/functions/certificate_expiry_slack"
  output_path = "${path.module}/.terraform/certificate-expiry-slack-alert.zip"
}

resource "azurerm_linux_function_app" "certificate_slack_alert" {
  count = local.certificate_slack_alert_enabled ? 1 : 0

  name                = "func-${local.namespace}-certalert"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_id     = azurerm_service_plan.certificate_slack_alert[0].id

  storage_account_name        = azurerm_storage_account.certificate_slack_alert[0].name
  storage_account_access_key  = azurerm_storage_account.certificate_slack_alert[0].primary_access_key
  functions_extension_version = "~4"
  zip_deploy_file             = data.archive_file.certificate_slack_alert[0].output_path

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    SLACK_WEBHOOK_URL        = var.slack_webhook_url
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  tags = local.common_tags
}

# Key Vault가 보내는 인증서 만료 임박/만료 이벤트만 Function으로 전달합니다.
resource "azurerm_eventgrid_event_subscription" "certificate_slack_alert" {
  count = local.certificate_slack_alert_enabled ? 1 : 0

  name  = "evgs-${local.namespace}-cert-slack"
  scope = module.agw.ssl_key_vault_id

  included_event_types = [
    "Microsoft.KeyVault.CertificateNearExpiry",
    "Microsoft.KeyVault.CertificateExpired",
  ]

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.certificate_slack_alert[0].id}/functions/${local.certificate_slack_function_name}"
  }

  retry_policy {
    max_delivery_attempts = 10
    event_time_to_live    = 1440
  }

  depends_on = [azurerm_linux_function_app.certificate_slack_alert]
}
