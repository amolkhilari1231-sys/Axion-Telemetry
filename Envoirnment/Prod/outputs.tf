output "resource_group_name" {
  description = "Production Resource Group Name"
  value       = "prod_rg"
}

output "postgresql_server_name" {
  description = "Production PostgreSQL Server Name"
  value       = "axionpostgresql-prod"
}

output "vm_name" {
  description = "Production Virtual Machine Name"
  value       = "axionbackendvm-prod"
}

output "app_gateway_name" {
  description = "Production Application Gateway Name"
  value       = "Axion-appgateway-prod"
}
