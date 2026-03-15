provider "aws" {
  region = "us-east-1"
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
