variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "ats-theme-dmo-b2bdatacolab"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast1"
}

# NEW: Environment variable
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}