terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random" }
  }
  backend "s3" {
    bucket       = "frontpagetybucket"
    key          = "frontpacitykey/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

# ----------------------------
# 1. Primary Site Resources
# ----------------------------
resource "aws_s3_bucket" "site" {
  bucket        = var.source_bucket_name
  force_destroy = var.force_destroy
  tags          = merge(local.common_tags, { Name = local.source_bucket_tag_name })
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}

# OAC for Secure CloudFront Access
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = local.oac_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ----------------------------
# 2. Replica Site Resources
# ----------------------------
resource "aws_s3_bucket" "site2" {
  provider      = aws.replica
  bucket        = var.replica_bucket_name
  force_destroy = var.force_destroy
  tags          = merge(local.common_tags, { Name = local.replica_bucket_tag_name })
}

resource "aws_s3_bucket_versioning" "site2" {
  provider = aws.replica
  bucket   = aws_s3_bucket.site2.id
  versioning_configuration { status = "Enabled" }
}

# ----------------------------
# 3. Replication Logic
# ----------------------------
resource "aws_iam_role" "replication" {
  name = "s3-replication-${random_id.replica_suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "s3.amazonaws.com" } }]
  })
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.site, aws_s3_bucket_versioning.site2]
  role       = aws_iam_role.replication.arn
  bucket     = aws_s3_bucket.site.id

  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination { bucket = aws_s3_bucket.site2.arn; storage_class = "STANDARD" }
  }
}

# ----------------------------
# 4. CloudFront Distribution
# ----------------------------
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = var.index_document
  aliases             = ["frontpagecity.com"]
  
  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f7" # Managed-CachingOptimized
    
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_uri.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  restrictions { geo_restriction { restriction_type = "none" } }
}

# ----------------------------
# 5. DNS & IAM (Simplified)
# ----------------------------
data "aws_route53_zone" "primary" { name = "frontpagecity.com" }

resource "aws_route53_record" "dns" {
  for_each = toset(["A", "AAAA"])
  zone_id  = data.aws_route53_zone.primary.zone_id
  name     = "frontpagecity.com"
  type     = each.value
  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}