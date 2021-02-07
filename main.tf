terraform {
  backend "s3" {
    // Intentionally empty, see:
    // - https://github.com/hashicorp/terraform/issues/13022
    // - https://www.terraform.io/docs/backends/config.html#partial-configuration
  }
}

locals {
  common_tags = {
    meta_tier  = "stack"
    meta_stack = "online_retail_example"
  }
}

resource "random_uuid" "store_table" {
}

resource "aws_dynamodb_table" "store_table" {
  name      = random_uuid.store_table.result
//  hash_key  = "uuid"
//  range_key = "item"
//  attribute {
//    name = "uuid"
//    type = "S"
//  }
//  attribute {
//    name = "item"
//    type = "S"
//  }
  hash_key = "key"
  attribute {
    name = "key"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"
  tags = merge(local.common_tags, {
    "name" : "store_catalog"
  })
}

resource "random_uuid" "store_create_item" {
}

resource "aws_ecr_repository" "store_create_item" {
  name                 = random_uuid.store_create_item.result
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = merge(local.common_tags, {
    "name" : "lambda_store_create_item"
  })
}

resource "aws_ecr_lifecycle_policy" "store_create_item" {
  repository = aws_ecr_repository.store_create_item.name
  policy     = file("ecr-lifecycle-policy.json")
}

resource "null_resource" "store_create_item" {
  triggers = {
    timestamp = timestamp()
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "docker tag creation-function:latest ${aws_ecr_repository.store_create_item.repository_url}:latest && docker push ${aws_ecr_repository.store_create_item.repository_url}:latest"
  }
}

data "aws_ecr_image" "service_image" {
  repository_name = aws_ecr_repository.store_create_item.name
  image_tag       = "latest"
  depends_on = [
    null_resource.store_create_item,
  ]
}

resource "aws_lambda_function" "store_create_item" {
  function_name = random_uuid.store_create_item.result
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.store_create_item.repository_url}@${data.aws_ecr_image.service_image.image_digest}"
  role          = aws_iam_role.store_create_item.arn
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.store_table.name
    }
  }
  tags = merge(local.common_tags, {
    "name" : "lambda_store_create_item"
  })
}

resource "aws_iam_role" "store_create_item" {
  name               = random_uuid.store_create_item.result
  assume_role_policy = data.aws_iam_policy_document.store_create_item_assumption_policy.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "store_create_item_assumption_policy" {
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

resource "aws_iam_role_policy" "store_create_item_permissions" {
  name   = random_uuid.store_create_item.result
  role   = aws_iam_role.store_create_item.id
  policy = data.aws_iam_policy_document.store_create_item_permissions.json
}

data "aws_iam_policy_document" "store_create_item_permissions" {
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
      aws_ecr_repository.store_create_item.arn,
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
      aws_dynamodb_table.store_table.arn,
    ]
  }
}
