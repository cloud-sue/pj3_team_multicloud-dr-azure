moved {
  from = azurerm_role_assignment.aks_acr_pull
  to   = module.rbac.azurerm_role_assignment.aks_acr_pull
}

moved {
  from = azurerm_role_assignment.agic_resource_group_reader
  to   = module.rbac.azurerm_role_assignment.agic_resource_group_reader
}

moved {
  from = azurerm_role_assignment.agic_application_gateway_contributor
  to   = module.rbac.azurerm_role_assignment.agic_application_gateway_contributor
}

moved {
  from = azurerm_role_assignment.agic_appgw_subnet_network_contributor
  to   = module.rbac.azurerm_role_assignment.agic_appgw_subnet_network_contributor
}

moved {
  from = module.keyvault.azurerm_key_vault_access_policy.terraform
  to   = module.keyvault.azurerm_key_vault_access_policy.secret_admins["feffdc93-e27f-43b7-85dc-f677d7708373"]
}
