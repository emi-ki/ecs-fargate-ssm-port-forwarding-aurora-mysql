variable "region" {
  description = "リソースを作成するリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "name_prefix" {
  description = "各リソース名のプレフィックス"
  type        = string
  default     = "emikihoge"
}

variable "vpc_cidr" {
  description = "VPC の CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "azs" {
  description = "使用するアベイラビリティーゾーン（2つ）"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットの CIDR（AZ ごと）"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "aurora_engine_version" {
  description = "Aurora MySQL のエンジンバージョン（接続先の本番環境に合わせる想定）"
  type        = string
  default     = "8.0.mysql_aurora.3.10.3"
}

variable "aurora_instance_class" {
  description = "Aurora のインスタンスクラス"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_name" {
  description = "初期データベース名"
  type        = string
  default     = "verifydb"
}

variable "db_master_username" {
  description = "DB マスターユーザー名"
  type        = string
  default     = "admin"
}

variable "db_port" {
  description = "DB のポート"
  type        = number
  default     = 3306
}
