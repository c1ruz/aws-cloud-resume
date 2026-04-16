output "website_url" {
  description = "Bucket website endpoint"

  value = aws_s3_bucket.s3_bucket.website_endpoint
}
