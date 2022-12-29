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
