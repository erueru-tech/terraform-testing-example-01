terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.19.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "5.19.0"
    }
  }
  required_version = "1.7.4"
}

provider "google" {
  project = local.project_id
  region  = var.region
}

provider "google-beta" {
  project = local.project_id
  region  = var.region
}

locals {
  project_id = join("-", [var.service, var.env])
}

# サービス名(この記事ではinfra-testing-google-sampleで固定)
variable "service" {
  type    = string
  default = null
}

# prod(本番)、stg(staging)、test(CI専用)、sbx-e(個人開発/検証用)などのサービスの環境を表す変数
variable "env" {
  type    = string
  default = null
  validation {
    condition     = contains(["prod", "stg", "test"], var.env) || startswith(var.env, "sbx-")
    error_message = "The value of var.env must be 'prod', 'stg', 'test' or start with 'sbx-', but it is '${var.env}'."
  }
}

# 以下の定義ならlocalsでリテラルの値を定義したほうがいいが、将来的に許可リージョンを増やすことを想定
variable "region" {
  type    = string
  default = "asia-northeast1"
  validation {
    condition     = var.region == "asia-northeast1"
    error_message = "The var.region value must be 'asia-northeast1', but it is '${var.region}'."
  }
}
