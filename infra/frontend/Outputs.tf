# ----------------------------
# Infrastructure Outputs
# ----------------------------

output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.site.bucket
}

output "replica_bucket_name" {
  description = "Name of the replica S3 bucket"
  value       = aws_s3_bucket.site2.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID for invalidation tasks"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "replication_role_arn" {
  description = "ARN of the S3 replication IAM role"
  value       = aws_iam_role.replication.arn
}