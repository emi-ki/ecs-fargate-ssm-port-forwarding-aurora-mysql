# =========================================================
# ECS Fargate 踏み台
#   - 常駐タスクを 1 つ起動（desired_count = 1）
#   - enable_execute_command = true で ECS Exec を有効化
#   - コンテナは何もしない常駐（amazonlinux を sleep）
#     本番の踏み台のように「SSM で入って先の RDS へ中継する」役
#   - イメージは ECR プルスルーキャッシュ経由で取得（ecr.tf 参照）
# =========================================================

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}-bastion"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "bastion" {
  family                   = "${var.name_prefix}-bastion"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name = "bastion"
      # 閉域では public.ecr.aws を直接 pull できないため、
      # プルスルーキャッシュ経由のプライベート ECR URI を参照する（ecr.tf 参照）
      image     = local.bastion_image
      essential = true
      # Security Hub ECS.5 対策: ルートファイルシステムを読み取り専用にする。
      # 踏み台は sleep で常駐するだけでルート FS への書き込みが不要なため問題ない。
      readonlyRootFilesystem = true
      # ルート FS を読み取り専用にするため、書き込みが要るパスだけ
      # tmpfs ボリュームをマウントする。
      #   /tmp              : シェルや一時処理用
      #   /var/lib/amazon   : ECS Exec の SSM エージェントが使う作業領域
      #   /var/log/amazon   : SSM エージェントのログ出力先
      # これらが読み取り専用だと ExecuteCommandAgent が起動できず
      # SSM 接続時に TargetNotConnected になるため、書き込み可能にする。
      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        },
        {
          sourceVolume  = "ssm-lib"
          containerPath = "/var/lib/amazon"
          readOnly      = false
        },
        {
          sourceVolume  = "ssm-log"
          containerPath = "/var/log/amazon"
          readOnly      = false
        }
      ]
      # 常駐させるだけ。中継は SSM の PortForwardingSessionToRemoteHost が担う
      command = ["sh", "-c", "while true; do sleep 3600; done"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "bastion"
        }
      }
    }
  ])

  # readonlyRootFilesystem との両立のための書き込み可能ボリューム
  volume {
    name = "tmp"
  }
  volume {
    name = "ssm-lib"
  }
  volume {
    name = "ssm-log"
  }

  tags = {
    Name = "${var.name_prefix}-bastion"
  }
}

resource "aws_ecs_service" "bastion" {
  name                   = "${var.name_prefix}-bastion-svc"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.bastion.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  tags = {
    Name = "${var.name_prefix}-bastion-svc"
  }
}
