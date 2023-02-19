resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"

  tags = {
    Name        = "example-bucket"
    Environment = "development"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.example.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.example.id
  key    = "index.html"
  source = "index.html"

  content_type = "text/html"
  etag = filemd5("index.html")
}
