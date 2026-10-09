# =========================================================
# 出力値
#   ポートフォワード接続に必要な値をまとめて出す
# =========================================================

output "region" {
  description = "リージョン"
  value       = var.region
}

output "ecs_cluster_name" {
  description = "ECS クラスタ名（start-session の target 組み立てに使う）"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS サービス名（list-tasks に使う）"
  value       = aws_ecs_service.bastion.name
}

output "bastion_image" {
  description = "踏み台タスクが参照するイメージ URI（プルスルーキャッシュ経由）"
  value       = local.bastion_image
}

output "aurora_endpoint" {
  description = "Aurora のライターエンドポイント（ポートフォワード先ホスト）"
  value       = aws_rds_cluster.this.endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora のリーダーエンドポイント"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "db_port" {
  description = "DB ポート"
  value       = var.db_port
}

output "db_name" {
  description = "初期データベース名"
  value       = var.db_name
}

output "db_master_username" {
  description = "DB マスターユーザー名"
  value       = var.db_master_username
}

output "secretsmanager_secret_name" {
  description = "接続情報を保存した Secrets Manager のシークレット名"
  value       = aws_secretsmanager_secret.db.name
}

output "db_password_cli_hint" {
  description = "パスワード取得コマンドのヒント"
  value       = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db.name} --query SecretString --output text | jq -r .password"
}
