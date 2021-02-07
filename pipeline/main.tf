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

data "aws_s3_bucket" "bootstrap_bucket" {
  bucket = var.bootstrap_bucket_name
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
      data.aws_s3_bucket.bootstrap_bucket.arn,
      "${data.aws_s3_bucket.bootstrap_bucket.arn}/*",
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
  statement {
    effect = "Allow"
    actions = [
      "codebuild:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_codebuild_project.deploy_infrastructure.arn,
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.deploy_infrastructure.name}:log-stream:",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.deploy_infrastructure.name}:log-stream:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "tag:GetResources",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
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
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*:log-stream:",
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*:log-stream:*",
      aws_codebuild_project.deploy_infrastructure.arn,
    ]
  }
  statement {
    # Potentially dangerous permissions broken into
    # a singular SID IAM statement for visibility
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:TagRole",
      "iam:GetRole",
      "iam:ListInstanceProfilesForRole",
      "iam:DeleteRole",
      "iam:GetRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:PassRole",
    ]
    resources = [
      "*"
    ]
  }
}

resource "random_uuid" "pipeline_poweruseraccess" {
}


resource "aws_iam_role_policy_attachment" "pipeline_poweruseraccess" {
  role       = aws_iam_role.pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
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
  lifecycle_rule {
    id      = "expire_1_day"
    enabled = true
    expiration {
      days = 1
    }
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
    name = "DeployApplication"
    action {
      name     = "DeployApplication"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      input_artifacts = [
        "github_source",
      ]
      version = "1"
      configuration = {
        ProjectName = aws_codebuild_project.deploy_infrastructure.name
      }
    }
  }
}

resource "random_uuid" "build_image" {}

data "aws_iam_policy_document" "build_image" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com",
      ]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:DeleteRepository",
      "ecr:BatchDeleteImage",
      "ecr:SetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy",
    ]
  }
}

resource "aws_codebuild_project" "deploy_infrastructure" {
  name         = "DeployInfrastructure"
  service_role = aws_iam_role.pipeline_role.arn
  description  = "Build and deploy the application"
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    //    image           = "${aws_ecr_repository.build_image.repository_url}:latest"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
  source {
    type = "CODEPIPELINE"
  }
  artifacts {
    type = "CODEPIPELINE"
  }
  tags = local.common_tags
}
