terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "4.67.0"
        }
        random = {
            source = "hashicorp/random"
            version = "3.5.1"
        }
    }
}

provider "google" {
    project = var.gcp_project_id
    region  = var.gcp_region
}
