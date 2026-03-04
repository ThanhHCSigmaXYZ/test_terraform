output "dataset_id" {
  value       = google_bigquery_dataset.test_dataset.dataset_id
  description = "Created BigQuery dataset"
}

output "repository_name" {
  value       = google_dataform_repository.repo.name
  description = "Created Dataform repository"
}

output "service_account_email" {
  value       = google_service_account.dataform_sa.email
  description = "Service Account email"
}
