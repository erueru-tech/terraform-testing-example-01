# 長い設定だが、Cloud SQL(MySQL)インスタンスを作成しているだけと捉える
# 設定の詳細について知りたい場合は、コメントを記載した下記URLのコードを参照
# https://github.com/erueru-tech/infra-testing-google-sample/blob/0.1.1/terraform/modules/db/main.tf
# ここでもGoogleが提供するブループリントであるsql-dbを使用してCloud SQLインスタンスを構築している
# sql-dbブループリントの仕様は以下README.mdを参照
# https://github.com/terraform-google-modules/terraform-google-sql-db/tree/master/modules/mysql
module "sql_db" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/mysql"
  version              = "19.0.0"
  project_id           = local.project_id
  region               = var.region
  zone                 = var.zone
  database_version     = "MYSQL_8_0_36"
  db_name              = var.db_name
  db_charset           = "utf8mb4"
  db_collation         = "utf8mb4_bin"
  availability_type    = var.availability_type
  name                 = var.db_instance_name
  random_instance_name = var.random_instance_name
  tier                 = var.tier
  user_name            = "sample-mysql-user"
  ip_configuration = {
    ipv4_enabled    = false
    private_network = var.vpc_id
  }
  backup_configuration = {
    binary_log_enabled = true
    enabled            = true
    start_time         = "21:00"
  }
  database_flags = [
    {
      name  = "slow_query_log"
      value = "on"
    },
    {
      name  = "long_query_time"
      value = "2"
    }
  ]
  deletion_protection         = var.deletion_protection
  deletion_protection_enabled = var.deletion_protection
  create_timeout              = "60m"
  module_depends_on           = [google_service_networking_connection.cloudsql_network_connection]
}

# 下記リソース群の定義はVPC内にCloud SQL(MySQL)インスタンスを作成するのに必要な設定
# 以下のURLのドキュメントを参考に定義
# https://cloud.google.com/sql/docs/mysql/samples/cloud-sql-mysql-instance-private-ip?hl=ja
# https://cloud.google.com/vpc/docs/configure-private-services-access?hl=ja
resource "google_compute_global_address" "cloudsql_ip_range" {
  name          = "sample-cloudsql-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = var.cloudsql_network_address
  prefix_length = 24
  network       = var.vpc_id
}

# destroy時に必ず削除に失敗するリソース
# https://github.com/hashicorp/terraform-provider-google/issues/16275
resource "google_service_networking_connection" "cloudsql_network_connection" {
  network                 = var.vpc_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloudsql_ip_range.name]
  # Terraform Testでテストコードを実行する上で必須となる設定(詳細はREADME.mdに記載されている記事参照)
  deletion_policy         = "ABANDON"
}

resource "google_compute_network_peering_routes_config" "cloudsql_peering_routes" {
  peering              = google_service_networking_connection.cloudsql_network_connection.peering
  network              = var.vpc_name
  import_custom_routes = true
  export_custom_routes = true
}
