output "github_connection_console_url" {
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/settings/${data.aws_caller_identity.current.account_id}/${data.aws_region.current.name}/connections/${replace(aws_codestarconnections_connection.main_gh_connection.id, "/.*:connection\\//", "")}"
  description = "By default the connection will stay in the 'pending' state until the user manually updates the connection in the console"
}

output "codepipeline_name" {
  value       = aws_codepipeline.main_pipe.name
  description = "Used by the AWS cli to kick off the pipeline"
}