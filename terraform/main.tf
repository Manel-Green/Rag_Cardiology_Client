terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "rag_assistant" {
  name     = var.bucket_name
  location = var.region
  versioning {
    enabled = true
  }
}

resource "google_document_ai_processor" "rag_assistant_ocr" {
  location     = var.document_ai_location
  display_name = "rag-cardiology-ocr"
  type         = "OCR_PROCESSOR"
}

resource "google_vertex_ai_index" "rag_assistant" {
  region       = var.region
  display_name = "rag-cardiology-index"
  description  = "Tree-AH index over cardiology RAG chunk embeddings"

  metadata {
    contents_delta_uri = "gs://${google_storage_bucket.rag_assistant.name}/processed/embeddings/vectors/"

    config {
      dimensions                  = 768
      approximate_neighbors_count = 10
      distance_measure_type       = "COSINE_DISTANCE"
      feature_norm_type           = "UNIT_L2_NORM"
      shard_size                  = "SHARD_SIZE_SMALL"

      algorithm_config {
        tree_ah_config {
          leaf_node_embedding_count    = 500
          leaf_nodes_to_search_percent = 10
        }
      }
    }
  }
}

resource "google_vertex_ai_index_endpoint" "rag_assistant" {
  region                  = var.region
  display_name            = "rag-cardiology-endpoint"
  public_endpoint_enabled = true
}

resource "google_cloud_run_v2_service" "rag_assistant_backend" {
  name     = "rag-cardiology-backend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "europe-west3-docker.pkg.dev/manel-rag-cardiology/cloud-run-source-deploy/rag-cardiology-backend@sha256:da52106b5bf62cf0f4cecafb5a8afb39ee7c167bf2aa17285ab163a979126b54"

      ports {
        container_port = 8080
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "VERTEX_LOCATION"
        value = var.region
      }
      env {
        name  = "INDEX_LOCATION"
        value = var.region
      }
      env {
        name  = "BUCKET"
        value = var.bucket_name
      }
      env {
        name  = "INDEX_ENDPOINT_RESOURCE_NAME"
        value = "projects/manel-rag-cardiology/locations/europe-west3/indexEndpoints/4996136856149032960"
      }
      env {
        name  = "DEPLOYED_INDEX_ID"
        value = "rag_cardiology_v1"
      }
      env {
        name  = "GENERATION_MODEL"
        value = "gemini-3.5-flash"
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 20
    }

    max_instance_request_concurrency = 80
    timeout                          = "300s"
  }
}

resource "google_cloud_run_v2_service_iam_member" "rag_assistant_public" {
  project  = google_cloud_run_v2_service.rag_assistant_backend.project
  location = google_cloud_run_v2_service.rag_assistant_backend.location
  name     = google_cloud_run_v2_service.rag_assistant_backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}