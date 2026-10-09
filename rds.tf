# =========================================================
# Aurora MySQL（接続先の本番環境とエンジンバージョンを合わせる想定）
#   - プライベートサブネットに配置
#   - パブリックアクセス無効
#   - パスワードは random_password で生成し Secrets Manager に保存
# =========================================================

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-subnetgp"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.name_prefix}-subnetgp"
  }
}

resource "random_password" "db" {
  length  = 20
  special = false
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.name_prefix}-aurora"
  engine             = "aurora-mysql"
  engine_version     = var.aurora_engine_version
  database_name      = var.db_name
  master_username    = var.db_master_username
  master_password    = random_password.db.result
  port               = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  apply_immediately   = true

  # 検証用途のため削除保護は無効（destroy しやすくする）
  deletion_protection = false

  tags = {
    Name = "${var.name_prefix}-aurora"
  }
}

resource "aws_rds_cluster_instance" "this" {
  identifier         = "${var.name_prefix}-aurora-1"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  publicly_accessible = false
  apply_immediately   = true

  tags = {
    Name = "${var.name_prefix}-aurora-1"
  }
}

# =========================================================
# 接続情報を Secrets Manager に保存
#   本番と同じく「Secrets Manager 参照で接続」する流れを再現する
# =========================================================
resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name_prefix}/aurora/credentials"
  description             = "Aurora MySQL credentials for port-forward verification"
  recovery_window_in_days = 0 # 検証用: 即時削除可能にする

  tags = {
    Name = "${var.name_prefix}-aurora-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_master_username
    password = random_password.db.result
    engine   = "mysql"
    host     = aws_rds_cluster.this.endpoint
    port     = var.db_port
    dbname   = var.db_name
  })
}
