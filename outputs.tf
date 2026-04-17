output "website_url" {
  description = "Bucket website endpoint"

  value = aws_s3_bucket_website_configuration.s3_bucket.website_endpoint
}
