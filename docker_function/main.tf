locals {
  common_tags = merge(var.tags, {
    "name" : var.function_name
  })
}

resource "random_uuid" "main" {
}

resource "aws_ecr_repository" "main" {
  name                 = random_uuid.main.result
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = file("ecr-lifecycle-policy.json")
}

resource "null_resource" "main" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "docker tag ${var.docker_image} ${aws_ecr_repository.main.repository_url}:latest && docker push ${aws_ecr_repository.main.repository_url}:latest"
  }
  depends_on = [
    aws_ecr_repository.main
  ]
}

data "aws_ecr_image" "main" {
  repository_name = aws_ecr_repository.main.name
  image_tag       = "latest"
  depends_on = [
    null_resource.main,
  ]
}

resource "aws_lambda_function" "main" {
  function_name = random_uuid.main.result
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.main.repository_url}@${data.aws_ecr_image.main.image_digest}"
  role          = aws_iam_role.main.arn
  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table.name
    }
  }
  depends_on = [
    aws_ecr_repository.main,
    null_resource.main,
    data.aws_ecr_image.main,
  ]
  tags = local.common_tags
}

resource "aws_iam_role" "main" {
  name               = random_uuid.main.result
  assume_role_policy = data.aws_iam_policy_document.main_role_assumption.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "main_role_assumption" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "main" {
  name   = random_uuid.main.result
  role   = aws_iam_role.main.id
  policy = data.aws_iam_policy_document.main_permissions.json
}

data "aws_iam_policy_document" "main_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "tag:GetResources",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:ListImages",
    ]
    resources = [
      aws_ecr_repository.main.arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem",
    ]
    resources = [
      var.dynamodb_table.arn,
    ]
  }
}