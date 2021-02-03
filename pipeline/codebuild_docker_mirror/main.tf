data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

resource "aws_ecr_repository" "docker_mirror" {
  for_each = var.docker_base_images

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_codebuild_project" "docker_mirror" {
  for_each = var.docker_base_images

  name = each.key
  //  service_role = aws_iam_role.pipeline_role.arn
  service_role = var.service_role.arn
  description  = "Docker hub has (rightly) created an API limit to prevent drain on their resources. This copies them."
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    //    image = "myAWS/codebuild/standard:1.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
  source {
    type = "NO_SOURCE"
    buildspec = templatefile("${path.module}/docker_buildspec.tpl", {
      aws_region     = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
      image          = each.value
      mirror         = aws_ecr_repository.docker_mirror[each.key].repository_url
    })
  }
  depends_on = [
    aws_ecr_repository.docker_mirror
  ]
}

resource "random_uuid" "codebuild_project_additional_permissions" {}

resource "aws_iam_role_policy" "codebuild_project_additional_permissions" {
  name   = random_uuid.codebuild_project_additional_permissions.result
  role   = var.service_role.id
  policy = data.aws_iam_policy_document.codebuild_project_additional_permissions.json
}

data "aws_iam_policy_document" "codebuild_project_additional_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = [
      "*",
    ]
  }
  dynamic "statement" {
    for_each = aws_codebuild_project.docker_mirror
    iterator = iterator
    content {
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
        "ecr:CompleteLayerUpload"
      ]
      resources = [
        iterator.value.arn,
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${iterator.key}:log-stream:",
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${iterator.key}:log-stream:*",
        aws_ecr_repository.docker_mirror[iterator.key].arn,
      ]
    }
  }
}