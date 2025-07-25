
output "postgresql_url" {
  description = "PostgreSQL database connection"
  value       = "postgresql://pgsync:pgsync123@localhost:5432/pgsync_db"
}

output "opensearch_url" {
  description = "OpenSearch cluster URL"
  value       = "http://localhost:9200"
}

output "opensearch_dashboard_url" {
  description = "OpenSearch Dashboard URL"
  value       = "http://localhost:5601"
}

output "pgsync_url" {
  description = "PGSync API URL"
  value       = "http://localhost:8080"
}

output "database_credentials" {
  description = "Database credentials"
  value = {
    postgres_admin_user     = "postgres"
    postgres_admin_password = "postgres123"
    pgsync_user            = "pgsync"
    pgsync_password        = "pgsync123"
    database_name          = "pgsync_db"
  }
  sensitive = true
}

