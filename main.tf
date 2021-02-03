
//resource "aws_lambda_function" "store_create_item" {
//  function_name = "store-create-item"
//  handler = ""
//  role = ""
//  runtime = ""
//}

resource "aws_dynamodb_table" "store_table" {
  name = "store-catalog"
  hash_key = "uuid"
  range_key = "item"
  attribute {
    name = "uuid"
    type = "S"
  }
  attribute {
    name = "item"
    type = "S"
  }

  billing_mode = "PAY_PER_REQUEST"
}


