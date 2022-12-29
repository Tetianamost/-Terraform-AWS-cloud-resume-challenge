resource "aws_s3_bucket" "resume_website" {
  bucket = "my-resume-website-latest"
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

resource "aws_cloudfront_distribution" "resume_website" {
  origin {
    domain_name = "www.example.com"
    origin_id   = "CustomOrigin"

    custom_origin_config {
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
    }
  }


  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.resume_website.arn
    ssl_support_method  = "sni-only"
  }

  enabled = true

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["resume.bythebeach.store", "bythebeach.store"]

  default_cache_behavior {
    target_origin_id       = "CustomOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
}
resource "aws_cloudfront_origin_access_identity" "resume_website" {
  comment = "OAI for resume website"
}

resource "aws_acm_certificate" "resume_website" {
  domain_name               = "bythebeach.store"
  subject_alternative_names = ["*.bythebeach.store"]
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_zone" "resume_website" {
  name = "bythebeach.store"
}
resource "aws_route53_record" "resume_website" {
  zone_id = aws_route53_zone.resume_website.zone_id
  name    = "resume.bythebeach.store"
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.resume_website.domain_name
    zone_id                = aws_cloudfront_distribution.resume_website.hosted_zone_id
    evaluate_target_health = true
  }
  depends_on = [aws_cloudfront_distribution.resume_website]
}
