output "dataset_id" {
  value       = google_bigquery_dataset.test_dataset.dataset_id
  description = "Created BigQuery dataset"
}

output "dataform_repository" {
  value       = google_dataform_repository.repo.name
  description = "Created Dataform repository"
}

output "service_account" {
  value       = google_service_account.dataform_sa.email
  description = "Service Account email"
}

output "dataform_console_url" {
  value       = "https://console.cloud.google.com/bigquery/dataform/locations/${var.region}/repositories/${google_dataform_repository.repo.name}?project=${var.project_id}"
  description = "Dataform Console URL"
}
