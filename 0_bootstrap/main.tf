provider "aws" {
  region = "us-east-1"
}

# Identity: Сервисный пользователь
resource "aws_iam_user" "tf_executor" {
  name = "terraform-service-account"
}

# State Storage: Корзина для стейта
resource "aws_s3_bucket" "tf_state" {
  bucket        = "danila-terekhov-cloud-rnd-tf-state-backend"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# State Locking: База данных (DynamoDB) для локов
resource "aws_dynamodb_table" "tf_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Генерация политики (ждет создания S3 и DynamoDB для получения их ARN)
data "aws_iam_policy_document" "tf_backend_policy" {
  # Доступ к корзине
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tf_state.arn]
  }

  # Доступ к объектам (самому стейту)
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tf_state.arn}/*"]
  }

  # Доступ к таблице блокировок
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.tf_locks.arn]
  }
}

resource "aws_iam_policy" "tf_backend" {
  name        = "TerraformBackendStrictAccess"
  description = "Least privilege policy for Terraform state management"
  policy      = data.aws_iam_policy_document.tf_backend_policy.json
}

# Аттач политики (ждет создания IAM User и IAM Policy)
resource "aws_iam_user_policy_attachment" "tf_executor_attach" {
  user       = aws_iam_user.tf_executor.name
  policy_arn = aws_iam_policy.tf_backend.arn
}
