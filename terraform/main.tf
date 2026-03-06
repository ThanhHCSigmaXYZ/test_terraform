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

# Enable APIs
resource "google_project_service" "dataform_api" {
  provider           = google-beta
  service            = "dataform.googleapis.com"
  disable_on_destroy = false
}

# BigQuery Dataset - WITH ENVIRONMENT PREFIX
resource "google_bigquery_dataset" "dataset" {
  project    = var.project_id
  dataset_id = "${var.environment}_dataform_dataset"  # ← CHANGED!
  location   = var.region
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Dataform Repository - WITH ENVIRONMENT PREFIX
resource "google_dataform_repository" "repo" {
  provider = google-beta
  
  project = var.project_id
  name    = "${var.environment}-dataform-repo"  # ← CHANGED!
  region  = var.region
  
  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
  
  depends_on = [google_project_service.dataform_api]
}

# Service Account - WITH ENVIRONMENT PREFIX
resource "google_service_account" "dataform_sa" {
  account_id   = "${var.environment}-dataform-sa"  # ← CHANGED!
  display_name = "${title(var.environment)} Dataform Service Account"
}