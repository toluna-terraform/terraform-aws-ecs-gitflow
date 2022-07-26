data "aws_s3_object" "s3_file1" {
  bucket = "s3-chef-non-prod"
  key = "test1_function.zip"
}

data "aws_s3_object" "s3_file2" {
  bucket = "s3-chef-non-prod"
  key = "test2_function.zip"
}