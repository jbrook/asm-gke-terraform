# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# CHECKME: Do we need all of these? Do we need others?

resource "google_project_service" "container_api" {
  service = "container.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "cloudresourcemanager_api" {
  #  project = local.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "mesh_api" {
  service = "mesh.googleapis.com"

  disable_dependent_services = true
}

# [START gke_ap_asm_tutorial_create_cluster]

terraform {
  required_version = "~> 1.3"
}

provider "google" {}

variable "region" {
  type        = string
  description = "Region where the cluster will be created."
  default     = "us-central1"
}

variable "network" {
  type        = string
  description = "The name or self_link of the network to connect the cluster to."
  default     = "default"
}

variable "cluster_name" {
  type        = string
  description = "Name of the cluster"
  default     = "asm-demo-cluster"
}

# CHECKME
#data "google_project" "project" {
#  depends_on = [google_project_service.cloudresourcemanager_api]
#}

resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.region
  network  = var.network

  # Enable Autopilot for this cluster
  enable_autopilot = true

  resource_labels = { mesh_id = "proj-${data.google_project.project.number}" }
}

# [END gke_ap_asm_tutorial_create_cluster]

# [START gke_ap_asm_configure_asm_fleet]

resource "google_gke_hub_membership" "membership" {
  membership_id = google_container_cluster.cluster.name
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.cluster.id}"
    }
  }
}

resource "google_gke_hub_feature" "service_mesh" {
  name     = "servicemesh"
  location = "global" # CHECKME

  depends_on = [
    google_project_service.mesh_api
  ]
}

resource "google_gke_hub_feature_membership" "service_mesh_for_membership" {
  location   = "global" # CHECKME
  feature    = google_gke_hub_feature.service_mesh.name
  membership = google_gke_hub_membership.membership.membership_id
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}

# [END gke_ap_asm_configure_asm_fleet]
