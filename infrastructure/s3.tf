resource "aws_s3_bucket" "terraform_state" {
  bucket = "ecs-terraform-state"
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}