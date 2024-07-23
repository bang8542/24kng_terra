resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# MediaConvert Role
resource "aws_iam_role" "mediaconvert_role" {
  name = "mediaconvert_role_${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "mediaconvert.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  mediaconvert_role_id = aws_iam_role.mediaconvert_role.id
}

resource "aws_iam_role_policy" "api_gateway_invoke_policy" {
  name = "api_gateway_invoke_policy_${random_string.suffix.result}"
  role = aws_iam_role.mediaconvert_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:Invoke",
          "execute-api:ManageConnections"
        ]
        Resource = "arn:aws:execute-api:*:*:*"
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy_${random_string.suffix.result}"
  role = aws_iam_role.mediaconvert_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::nonoinput",
          "arn:aws:s3:::nonoinput/*",
          "arn:aws:s3:::nonooutput",
          "arn:aws:s3:::nonooutput/*",
          "arn:aws:s3:::nonooutput-us-east-1",
          "arn:aws:s3:::nonooutput-us-east-1/*",
          "arn:aws:s3:::nonooutput-ca-central-1",
          "arn:aws:s3:::nonooutput-ca-central-1/*"
        ]
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda VOD Execution Role
resource "aws_iam_role" "lambda_vod_execution" {
  name = "lambda_vod_execution_${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  lambda_vod_execution_id = aws_iam_role.lambda_vod_execution.id
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_vod_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "lambda_vod_execution_policy" {
  name = "lambda_vod_execution_policy_${random_string.suffix.result}"
  role = aws_iam_role.lambda_vod_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::nonoinput",
          "arn:aws:s3:::nonoinput/*",
          "arn:aws:s3:::nonooutput",
          "arn:aws:s3:::nonooutput/*",
          "arn:aws:s3:::nonooutput-us-east-1",
          "arn:aws:s3:::nonooutput-us-east-1/*",
          "arn:aws:s3:::nonooutput-ca-central-1",
          "arn:aws:s3:::nonooutput-ca-central-1/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "mediaconvert:CreateJob",
          "mediaconvert:GetJob",
          "mediaconvert:ListJobs",
          "mediaconvert:CancelJob",
          "mediaconvert:DescribeEndpoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.mediaconvert_role.arn
      },
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = "arn:aws:lambda:ap-northeast-2:975049989858:function:create_mediaconvert_job*"
      }
    ]
  })

  lifecycle {
    create_before_destroy = true
  }
}
