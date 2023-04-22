variable "region" {
  type        = string
  description = "the AWS region in which resources are created"
  default     = "eu-central-1"
}

variable "access_key" {
  type        = string
  description = "aws access key account"
}

variable "secret_key" {
  type        = string
  description = "aws access key account"
}