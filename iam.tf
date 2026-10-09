# =========================================================
# IAM ロール
#   - 実行ロール（execution role）: イメージ取得・ログ出力
#   - タスクロール（task role）    : ECS Exec / SSM セッション用
# =========================================================

data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- 実行ロール ---
resource "aws_iam_role" "task_execution" {
  name               = "${var.name_prefix}-task-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- タスクロール ---
resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# ECS Exec / SSM ポートフォワードに必要な権限
data "aws_iam_policy_document" "task_ssm" {
  statement {
    sid    = "SSMMessages"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_ssm" {
  name   = "${var.name_prefix}-task-ssm-policy"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_ssm.json
}
