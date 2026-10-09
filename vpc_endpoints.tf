# =========================================================
# VPC エンドポイント
#   SSM ポートフォワード（ECS Exec）に必要な通信経路を
#   NAT Gateway なしで閉域に確保する。
#
#   Interface 型:
#     - ssm            : Session Manager API
#     - ssmmessages    : Session Manager のデータチャネル
#     - ecr.api / ecr.dkr : ECR からのイメージ取得
#     - logs           : CloudWatch Logs へのログ送信
#   Gateway 型:
#     - s3             : ECR のイメージレイヤ取得（S3 バックエンド）に必要
# =========================================================

locals {
  interface_endpoints = [
    "ssm",
    "ssmmessages",
    "ecr.api",
    "ecr.dkr",
    "logs",
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-vpce-${each.value}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.name_prefix}-vpce-s3"
  }
}
