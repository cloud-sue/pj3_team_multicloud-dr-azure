locals {
  secondary_target_hostname = (
    try(trimspace(var.secondary_target), "") == ""
    ? ""
    : split(
      "/",
      replace(
        replace(trimspace(var.secondary_target), "https://", ""),
        "http://",
        ""
      )
    )[0]
  )

  names = {
    profile            = "tm-${var.namespace}"
    primary_endpoint   = "primary-appgw"
    secondary_endpoint = "secondary-aws"
  }

  profile = {
    status            = "Enabled"
    routing_method    = "Priority"
    dns_relative_name = "tm-${var.namespace}"
    dns_ttl           = 30

    # 공개 DNS는 Traffic Manager를 바라보므로 실제 사용자 경로와 같은 HTTPS 443으로 상태를 확인합니다.
    monitor_protocol      = "HTTPS"
    monitor_port          = 443
    monitor_path          = "/healthz"
    monitor_status_ranges = ["200-399"]
    monitor_interval      = 30
    monitor_timeout       = 10
    monitor_failure_count = 3

    primary_priority       = 1
    secondary_priority     = 2
    endpoint_enabled       = true
    secondary_target       = local.secondary_target_hostname
    has_secondary_endpoint = var.enable_secondary_endpoint && local.secondary_target_hostname != ""
  }

  primary_endpoint = {
    name     = local.names.primary_endpoint
    target   = var.primary_target
    priority = local.profile.primary_priority
    enabled  = local.profile.endpoint_enabled
  }

  secondary_endpoint = {
    name     = local.names.secondary_endpoint
    target   = local.profile.secondary_target
    priority = local.profile.secondary_priority
    enabled  = local.profile.endpoint_enabled
  }
}
