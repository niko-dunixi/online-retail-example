locals {
  common_tags = {
    meta_tier  = "bootstrap"
    meta_stack = "online_retail_example"
  }
  tf_version = "0.14.5"
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

// This works if you're running terraform from a binary, but the docker image doesn't have bash installed
// Keepting this snippet here for reference
//resource "null_resource" "terraform_linux_zip" {
//  triggers = {
//    on_change = local.tf_version
//  }
//  provisioner "local-exec" {
//    interpreter = ["/bin/bash", "-c"]
//    command     = "curl -JLO https://releases.hashicorp.com/terraform/${local.tf_version}/terraform_${local.tf_version}_linux_amd64.zip"
//  }
//}

resource "aws_s3_bucket_object" "terraform_linux_zip" {
  bucket = random_uuid.bucket_uuid.result
  key    = "tools/terraform_${local.tf_version}_linux_amd64.zip"
  source = "./terraform_${local.tf_version}_linux_amd64.zip"
  //  etag   = filemd5("${path.cwd}/terraform_${local.tf_version}_linux_amd64.zip")
}
