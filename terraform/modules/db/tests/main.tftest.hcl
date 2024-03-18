# 以下のテストをterraform testコマンドで実行する際、TF_VAR_xxxで正しいservice、env、cloudsql_network_addressの値を渡す必要がある
# 例: erueru-techの個人環境でテストを実行する場合(cloudsql_network_addressの値を実行環境に合わせたCIDRにする)
# $ cd /path/to/terraform-testing-example-01/terraform/modules/db
# $ terraform init
# $ TF_VAR_service=infra-testing-google-sample \
#   TF_VAR_env=sbx-e \
#   # test環境では10.3.102.0
#   TF_VAR_cloudsql_network_address=10.4.102.0 \
#   terraform test -filter=tests/main.tftest.hcl
#
# 上記テスト完了後、クリーンアップのために以下のコマンドを実行する必要がある
# 詳細はmain.tfのgoogle_service_networking_connectionリソースのコメント参照
# $ gcloud compute networks peerings delete servicenetworking-googleapis-com --network sample-vpc --project プロジェクト名
variables {
  # 以下のassertでは使用されないが、variables.tfで必須として宣言されている変数
  # 先ほどsandbox環境に作成したVPCの名前を指定
  vpc_name = "sample-vpc"
}

run "apply_db" {
  variables {
    # 以下のassertでは使用されないが、variables.tfで必須として宣言されている変数
    # 上のvariablesで宣言しないのは${var.vpc_name}のように変数の参照をトップレベルで宣言するとエラーになるため
    vpc_id = "projects/${var.service}-${var.env}/global/networks/${var.vpc_name}"
  }
  # Cloud SQLインスタンスの接続エンドポイント名が意図する値であることを確認
  assert {
    condition     = can(regex("^${var.service}-${var.env}:asia-northeast1:sample-instance-[a-z0-9]{8}$", output.mysql_main_connection_name))
    error_message = "The output.mysql_main_connection_name value isn't expected. Please see the above values."
  }
  # Cloud SQLインスタンスが配置されたサブネットのネットワークアドレスが意図する範囲であることを確認
  assert {
    condition     = can(regex("^10.4.102.([2-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-3])$", output.mysql_main_private_ip_address))
    error_message = "The output.mysql_main_private_ip_address value isn't expected. Please see the above value."
  }
  # Cloud SQLインスタンスにPublic IPが割り当てられていないことを確認
  assert {
    condition     = output.mysql_main_public_ip_address == ""
    error_message = "Cloud SQL instance can be accessed from public network."
  }
  # MySQL接続用ユーザのパスワードが32文字であることを確認
  assert {
    condition     = length(nonsensitive(output.mysql_main_user_password)) == 32
    error_message = "The length of the output.mysql_main_user_password must be 32."
  }
}
