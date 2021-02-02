terraform {
  backend "s3" {
    // Intentionally empty, see:
    // - https://github.com/hashicorp/terraform/issues/13022
    // - https://www.terraform.io/docs/backends/config.html#partial-configuration
  }
}

locals {
  common_tags = {
    meta_tier  = "pipeline"
    meta_stack = "online_retail_example"
  }
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "random_uuid" "pipeline_role" {
}

resource "aws_iam_role" "pipeline_role" {
  name               = random_uuid.pipeline_role.result
  assume_role_policy = data.aws_iam_policy_document.pipeline_role.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "pipeline_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com",
        "codebuild.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role_policy" "pipeline_role_permissions" {
  name   = random_uuid.pipeline_role.result
  role   = aws_iam_role.pipeline_role.id
  policy = data.aws_iam_policy_document.pipeline_role_permissions.json
}

data "aws_iam_policy_document" "pipeline_role_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [
      aws_codestarconnections_connection.main_gh_connection.arn
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject*",
    ]
    resources = [
      aws_s3_bucket.main_bucket.arn,
      "${aws_s3_bucket.main_bucket.arn}/*",
      "arn:aws:s3:::${aws_s3_bucket.main_bucket.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.main_bucket.id}",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.pipeline_role.arn
    ]
  }
}


resource "random_uuid" "main_bucket" {
}

resource "aws_s3_bucket" "main_bucket" {
  bucket = random_uuid.main_bucket.result
  tags   = local.common_tags
  acl    = "private"
  versioning {
    enabled = false
  }
}

resource "aws_s3_bucket_policy" "main_bucket" {
  bucket = aws_s3_bucket.main_bucket.id
  policy = data.aws_iam_policy_document.main_bucket.json
}

data "aws_iam_policy_document" "main_bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:List*",
      "s3:PutObject*",
    ]
    principals {
      type = "Service"
      identifiers = [
        "codepipeline.amazonaws.com",
        "codebuild.amazonaws.com",
      ]
    }
    resources = [
      aws_s3_bucket.main_bucket.arn,
      "${aws_s3_bucket.main_bucket.arn}/*",
      "arn:aws:s3:::${aws_s3_bucket.main_bucket.id}/*",
      "arn:aws:s3:::${aws_s3_bucket.main_bucket.id}",
    ]
  }
}

resource "random_uuid" "main_gh_connection" {
}

resource "aws_codestarconnections_connection" "main_gh_connection" {
  name          = substr(random_uuid.main_gh_connection.result, 0, 32)
  provider_type = "GitHub"
}

module "codebuild_docker_mirrors" {
  source = "./codebuild_docker_mirror"
  service_role = {
    arn = aws_iam_role.pipeline_role.arn
    id  = aws_iam_role.pipeline_role.id
  }
  docker_base_images = {
    "golang" : "golang:1.15.7"
  }
}

resource "random_uuid" "main_pipe" {
}

resource "aws_codepipeline" "main_pipe" {
  name     = random_uuid.main_pipe.result
  role_arn = aws_iam_role.pipeline_role.arn
  tags     = local.common_tags

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.main_bucket.bucket
  }

  stage {
    name = "GitHubSource"

    action {
      name     = "Source"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"
      output_artifacts = [
        "github_source",
      ]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.main_gh_connection.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repository}"
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "DockerHubMirror"

    dynamic "action" {
      for_each = module.codebuild_docker_mirrors.codebuild_project_names
      iterator = image_iterator
      content {
        name     = image_iterator.value
        category = "Build"
        owner    = "AWS"
        provider = "CodeBuild"
        version  = "1"

        input_artifacts = [
          "github_source",
        ]
        configuration = {
          ProjectName = image_iterator.value
        }
      }
    }
  }
}

