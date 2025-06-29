output "db_name" {
  description = "The name of the PostgreSQL database."
  value       = module.stable_transactions_db.db_name
}

output "db_endpoint" {
  description = "The endpoint of the PostgreSQL database."
  value       = module.stable_transactions_db.db_endpoint
}

output "db_port" {
  description = "The port of the PostgreSQL database."
  value       = module.stable_transactions_db.db_port
}

output "db_identifier" {
  description = "The RDS instance identifier."
  value       = module.stable_transactions_db.db_identifier
}
