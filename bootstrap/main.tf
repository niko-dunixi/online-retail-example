locals {
  common_tags = {
    meta_tier  = "bootstrap"
    meta_stack = "online_retail_example"
  }
}

resource "random_uuid" "bucket_uuid" {
}

resource "aws_s3_bucket" "bootstrap_bucket" {
  bucket = random_uuid.bucket_uuid.result
  acl    = "private"
  versioning {
    enabled = true
  }
  tags = local.common_tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "random_uuid" "table_uuid" {
}

resource "aws_dynamodb_table" "bootstrap_table" {
  name     = random_uuid.table_uuid.result
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  billing_mode = "PAY_PER_REQUEST"
  tags         = local.common_tags
  lifecycle {
    prevent_destroy = true
  }
}