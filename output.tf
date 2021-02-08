output "api" {
  value = {
    key       = aws_appsync_api_key.main_api.key
    url       = aws_appsync_graphql_api.main_api.uris["GRAPHQL"]
    websocket = aws_appsync_graphql_api.main_api.uris["REALTIME"]
  }
}