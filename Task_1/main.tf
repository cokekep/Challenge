provider "aws" {
  region     = "eu-central-1"
  profile = "iamadmin-vahiwe"
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "s3-website-test.vahiwe.com"
  force_destroy = true
  acl    = "public-read"
  policy = file("policy.json")

  website {
    index_document = "index.html"
    error_document = "error.html"

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }
}

resource "null_resource" "remove_and_upload_to_s3" {
  provisioner "local-exec" {
    command = "aws s3 --profile iamadmin-vahiwe sync ${path.module}/web s3://${aws_s3_bucket.s3_bucket.id}"
  }
}