# terraform.tf
terraform {
  backend "gcs" {
    prefix  = "terraform/tier1-state"
  }
}

# tier1-variables.tf
# VPC内に作成されるサブネットのCIDR
variable "subnet_ip" {
  type    = string
  default = null
  validation {
    condition     = var.subnet_ip != null
    error_message = "The var.subnet_ip value is required."
  }
}

# tier1-main.tf
# TerraformがGCPの各種サービスのAPIに接続するために必要な設定
module "project_services" {
  source     = "terraform-google-modules/project-factory/google//modules/project_services"
  version    = "14.4.0"
  project_id = local.project_id
  activate_apis = [
    "bigquery.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "datastore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com"
  ]
  # destroy発行時に上記APIが全て無効化されないようにする設定
  disable_services_on_destroy = false
}

# VPCを作成
module "network" {
  source       = "../../../modules/network"
  service      = var.service
  env          = var.env
  subnet_ip    = var.subnet_ip
}

# tier1-outputs.tf
output "vpc_id" {
  value = module.network.vpc_id
}

output "vpc_name" {
  value = module.network.vpc_name
}
