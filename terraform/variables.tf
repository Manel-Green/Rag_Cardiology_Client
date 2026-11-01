variable "project_id" {
  description = "The GCP project ID to deploy into"
  type        = string
}

variable "region" {
  description = "The GCP region for most resources"
  type        = string
  default     = "europe-west3"
}

variable "bucket_name" {
  description = "The GCS bucket name for raw PDFs and processed data"
  type        = string
}

variable "document_ai_location" {
  description = "Region for the Document AI processor"
  type        = string
  default     = "eu"
}