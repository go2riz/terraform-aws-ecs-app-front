resource "aws_cloudfront_distribution" "default" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.hostname
  aliases             = distinct(compact(concat([var.hostname], [for h in split(",", var.hostname_redirects) : trimspace(h)], var.hostname_blue == "" ? [] : [var.hostname_blue])))
  price_class         = "PriceClass_All"
  wait_for_deployment = false

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "default"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "fromcloudfront"
      value = var.alb_cloudfront_key
    }

    lifecycle {
        ignore_changes = [aliases]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "default"
    compress         = true

    forwarded_values {
      query_string = true
      headers      = var.cloudfront_forward_headers

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  web_acl_id = var.cloudfront_web_acl_id
}
