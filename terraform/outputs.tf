output "environment" {
  value       = var.environment
  description = "Current environment"
}

output "dataset_id" {
  value       = google_bigquery_dataset.dataset.dataset_id
  description = "BigQuery dataset ID"
}

output "dataform_repository" {
  value       = google_dataform_repository.repo.name
  description = "Dataform repository name"
}

output "service_account_email" {
  value       = google_service_account.dataform_sa.email
  description = "Service account email"
}

output "summary" {
  value = <<-EOT
    Environment: ${var.environment}
    Dataset: ${google_bigquery_dataset.dataset.dataset_id}
    Dataform Repo: ${google_dataform_repository.repo.name}
    Service Account: ${google_service_account.dataform_sa.email}
  EOT
  description = "Deployment summary"
}