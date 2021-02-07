variable "function_name" {
  type = string
}

variable "docker_image" {
  type = string
}

variable "dynamodb_table" {
  type = object({
    arn = string
    name = string
  })
}

variable "tags" {
  type = map(string)
}