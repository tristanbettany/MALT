data "archive_file" "lambda_archive" {
  type        = "zip"
  source_dir  = "${path.cwd}/../"
  excludes    = var.files_to_exclude_from_zip
  output_path = "${path.module}/${var.env_ms_name}.zip"
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = lower(var.env_ms_name)
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "lambda_bucket_object" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "${var.env_ms_name}.zip"
  source = data.archive_file.lambda_archive.output_path
  etag   = filemd5(data.archive_file.lambda_archive.output_path)
}

