variable "service_role" {
  type = object({
    arn = string
    id  = string
  })
}

variable "docker_base_images" {
  type = map(string)
}