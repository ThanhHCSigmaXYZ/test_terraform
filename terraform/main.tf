terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable Dataform API
resource "google_project_service" "dataform_api" {
  provider = google-beta
  service  = "dataform.googleapis.com"
  disable_on_destroy = false
}

# BigQuery Dataset
resource "google_bigquery_dataset" "test_dataset" {
  project    = var.project_id
  dataset_id = "github_actions_test"
  location   = var.region
  
  labels = {
    created_by = "github-actions"
    purpose    = "ci-cd-test"
  }
}

# Dataform Repository
resource "google_dataform_repository" "repo" {
  provider = google-beta
  
  project = var.project_id
  name    = "github-actions-dataform"
  region  = var.region
  
  labels = {
    managed_by = "github-actions"
  }
  
  depends_on = [google_project_service.dataform_api]
}

# Service Account
resource "google_service_account" "dataform_sa" {
  account_id   = "github-actions-dataform"
  display_name = "GitHub Actions Dataform SA"
}
