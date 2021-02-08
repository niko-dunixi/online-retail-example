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
  name     = random_uuid.store_table.result
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

module "create_store_function" {
  source        = "./docker_function"
  function_name = "create_store_item"
  docker_image  = "creation-function:latest"
  dynamodb_table = {
    arn  = aws_dynamodb_table.store_table.arn
    name = aws_dynamodb_table.store_table.name
  }
  tags = local.common_tags
}

resource "random_uuid" "main_api" {
}

resource "aws_appsync_graphql_api" "main_api" {
  # Note, this will succeed without the substr. The AWS API doesn't enforce the restriction
  # while their UI does. To prevent trouble for ourselves down the line (should they realize)
  # we'll get ahead of the issue and be a good neighbor.
  name                = substr(random_uuid.main_api.result, 0, 32)
  authentication_type = "API_KEY"
  schema              = file("schema.graphql")
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync.arn
    field_log_level          = "ALL"
    //    field_log_level          = "ERROR"
  }
}

resource "aws_appsync_api_key" "main_api" {
  api_id  = aws_appsync_graphql_api.main_api.id
  expires = "2021-03-01T00:00:00Z"
}

resource "aws_appsync_datasource" "creation_function" {
  api_id           = aws_appsync_graphql_api.main_api.id
  name             = "create_function"
  type             = "AWS_LAMBDA"
  service_role_arn = aws_iam_role.appsync.arn
  lambda_config {
    function_arn = module.create_store_function.lambda_arn
  }
}

resource "aws_appsync_resolver" "creation_function" {
  api_id      = aws_appsync_graphql_api.main_api.id
  type        = "Mutation"
  field       = "create"
  data_source = aws_appsync_datasource.creation_function.name
  request_template = templatefile("appsync_create_function_request.json.tpl", {
  })
  response_template = templatefile("appsync_create_function_response.json.tpl", {
  })
}

//resource "aws_appsync_function" "creation_function" {
//  name        = "creation_function"
//  api_id      = aws_appsync_graphql_api.main_api.id
//  data_source = aws_appsync_datasource.creation_function.name
//  request_mapping_template = templatefile("appsync_create_function_request.json.tpl", {
//  })
//  response_mapping_template = templatefile("appsync_create_function_response.json.tpl", {
//  })
//}

resource "random_uuid" "appsync_role" {
}

resource "aws_iam_role" "appsync" {
  name               = random_uuid.appsync_role.result
  assume_role_policy = data.aws_iam_policy_document.appsync_assumption.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "appsync_assumption" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "appsync.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "appsync_permissions" {
  name   = random_uuid.appsync_role.result
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync_permissions.json
}

data "aws_iam_policy_document" "appsync_permissions" {
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
      "lambda:InvokeFunction",
    ]
    resources = [
      module.create_store_function.lambda_arn,
    ]
  }
}
