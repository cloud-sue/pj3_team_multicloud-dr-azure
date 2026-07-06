locals {
  default_ttl = 300 # 레코드가 서버에 저장되어 있는 유효 시간

  dns_zone_config = {
    name                = "sue019522.shop"
    resource_group_name = var.resource_group_name
    tags                = var.tags
  }

  root_a_record = {
    name    = "@"
    ttl     = local.default_ttl
    records = [var.root_a_record_ip]
    tags    = var.tags
  }

  www_cname_record = {
    name   = "www"
    ttl    = local.default_ttl
    record = var.traffic_manager_fqdn
    tags   = var.tags
  }

  # ACM certificate DNS validation
  acm_validation_cname_records = {
    www = {
      name   = "_945f5cc3b9c993bdd0cec13cb7506c71.www"
      ttl    = local.default_ttl
      record = "_6efe96f41494cc72718384316aeb42c6.jkddzztszm.acm-validations.aws"
      tags   = var.tags
    }
    root = {
      name   = "_3496e98b6513dd4c0d0f4c3d0cfda26c"
      ttl    = local.default_ttl
      record = "_303f48765bc895fcdde06876f1190c15.jkddzztszm.acm-validations.aws"
      tags   = var.tags
    }
  }
}
