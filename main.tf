terraform {
  backend "s3" {
    // Intentionally empty, see:
    // - https://github.com/hashicorp/terraform/issues/13022
    // - https://www.terraform.io/docs/backends/config.html#partial-configuration
  }
}

locals {
  common_tags = {
    meta_tier = "stack"
    meta_stack = "online_retail_example"
  }
}

resource "random_uuid" "store_table" {
}

resource "aws_dynamodb_table" "store_table" {
  name = random_uuid.store_table.result
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
  source = "./docker_function"
  function_name = "create_store_item"
  docker_image = "creation-function:latest"
  dynamodb_table = {
    arn = aws_dynamodb_table.store_table.arn
    name = aws_dynamodb_table.store_table.name
  }
  tags = local.common_tags
}
