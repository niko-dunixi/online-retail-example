output "codebuild_project_names" {
  value = [for mirror in aws_codebuild_project.docker_mirror : mirror.name]
}