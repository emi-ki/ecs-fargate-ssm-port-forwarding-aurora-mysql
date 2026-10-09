# =========================================================
# セキュリティグループ
#   - ECS タスク用（アウトバウンドのみ）
#   - RDS 用（ECS タスクSGからの DB ポートのみ許可）
#   - VPC エンドポイント用（VPC 内からの 443 を許可）
# =========================================================

# ECS Fargate 踏み台タスク用 SG
resource "aws_security_group" "ecs" {
  name        = "${var.name_prefix}-ecs-sg"
  description = "ECS Fargate bastion task SG"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-ecs-sg"
  }
}

# Aurora 用 SG（ECS タスク SG からの DB ポートのみ許可）
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Aurora MySQL SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "DB access from ECS bastion task"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

# VPC エンドポイント（Interface 型）用 SG
#   - VPC 内からの HTTPS(443) を許可
resource "aws_security_group" "vpce" {
  name        = "${var.name_prefix}-vpce-sg"
  description = "VPC Interface Endpoint SG"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from within VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-vpce-sg"
  }
}
