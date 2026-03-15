provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "danila-terekhov-cloud-rnd-tf-state-backend"
    key    = "global/free-tier-activities/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

# Free Tier Activities Resources

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 1. EC2 Instance (Free Tier eligible: t2.micro or t3.micro)
resource "aws_instance" "free_tier" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  tags = {
    Name = "FreeTierInstance"
  }
}

# 2. Lambda Function with Function URL (Free Tier eligible)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "free_tier" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "free_tier_function"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      ENVIRONMENT = "free_tier"
    }
  }
}

resource "aws_lambda_function_url" "free_tier" {
  function_name      = aws_lambda_function.free_tier.function_name
  authorization_type = "NONE"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 3. AWS Budgets (Free Tier)
resource "aws_budgets_budget" "free_tier" {
  name              = "free-tier-budget"
  budget_type       = "COST"
  limit_amount      = "100"
  limit_unit        = "USD"
  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"
}

# 4. RDS Database (Free Tier eligible: db.t2.micro or db.t3.micro)
resource "aws_db_instance" "free_tier" {
  identifier          = "free-tier-db"
  engine              = "mysql"
  engine_version      = "8.0"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = "admin"
  password            = "ChangeMe123!"
  skip_final_snapshot = true

  tags = {
    Name = "FreeTierDB"
  }
}

# 5. Bedrock - No actual resource needed, just access via console
# Bedrock is a managed service, no Terraform resources required for playground usage

