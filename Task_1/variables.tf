variable "zone_id" {
  description = "Hosted Zone ID"
  type        = string
  default = ""
}

variable "bucket_name" {
  description = "S3 Bucket Name"
  type        = string
  default = ""
}

variable "region" {
  description = "AWS region"
  type        = string
  default = ""
}

variable "aws_cli_profile" {
  description = "AWS profile"
  type        = string
  default = ""
}

variable "acm_certificate_arn" {
  description = "ACM Certificate created in us-east-1 for cloudfront Distribution"
  type        = string
  default = ""
}