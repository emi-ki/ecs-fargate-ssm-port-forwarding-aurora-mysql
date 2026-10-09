# =========================================================
# ECR プルスルーキャッシュ
#   閉域（NAT なし）では public.ecr.aws から直接 pull できないため、
#   自分のアカウントの ECR をキャッシュ入口にする。
#
#   ECS タスクが初回 pull すると、ECR が裏で upstream
#   （public.ecr.aws）から取得し、プライベート ECR にキャッシュする。
#   ECS タスクから見た取得先は常にプライベート ECR になるため、
#   VPC エンドポイント（ecr.api / ecr.dkr / s3）経由で閉域のまま届く。
# =========================================================

# アカウント ID を取得（イメージ URI の組み立てに使う）
data "aws_caller_identity" "current" {}

locals {
  # プルスルーキャッシュのプレフィックス
  ecr_pullthrough_prefix = "ecr-public"

  # ECS タスクが参照するイメージ URI
  #   <account>.dkr.ecr.<region>.amazonaws.com/<prefix>/<upstreamのパス>:<tag>
  bastion_image = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/${local.ecr_pullthrough_prefix}/amazonlinux/amazonlinux:2023"
}

# public.ecr.aws 向けのプルスルーキャッシュルール
resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = local.ecr_pullthrough_prefix
  upstream_registry_url = "public.ecr.aws"
}

# =========================================================
# キャッシュ初回作成時の権限
#   初回 pull 時、ECR はキャッシュ用リポジトリを自動作成し、
#   upstream からイメージを取り込む。これには実行ロール側に
#   ecr:CreateRepository と ecr:BatchImportUpstreamImage が必要。
# =========================================================
data "aws_iam_policy_document" "pullthrough" {
  statement {
    sid    = "ECRPullThroughCache"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository",
      "ecr:BatchImportUpstreamImage",
      "ecr:TagResource",
    ]
    resources = [
      "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${local.ecr_pullthrough_prefix}/*",
    ]
  }
}

resource "aws_iam_role_policy" "task_execution_pullthrough" {
  name   = "${var.name_prefix}-exec-pullthrough-policy"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.pullthrough.json
}
