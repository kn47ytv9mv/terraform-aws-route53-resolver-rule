resource "aws_route53_resolver_rule" "resource" {
  domain_name          = var.domain_name
  rule_type            = var.rule_type
  resolver_endpoint_id = var.resolver_endpoint_id

  dynamic "target_ip" {
    for_each = { for t in var.target_ips : coalesce(t.ip, t.ipv6) => t }

    content {
      ip       = target_ip.value.ip
      ipv6     = target_ip.value.ipv6
      port     = target_ip.value.port
      protocol = target_ip.value.protocol
    }
  }

  tags = merge(var.tags, { name = "resolver-rule" })
}

resource "aws_route53_resolver_rule_association" "resource" {
  count = length(var.vpc_ids)

  resolver_rule_id = aws_route53_resolver_rule.resource.id
  vpc_id           = var.vpc_ids[count.index]
}

output "id" {
  description = "The ID of the resolver rule."
  value       = aws_route53_resolver_rule.resource.id
}

output "arn" {
  description = "The ARN of the resolver rule."
  value       = aws_route53_resolver_rule.resource.arn
}

output "owner_id" {
  description = "AWS account ID that owns the rule."
  value       = aws_route53_resolver_rule.resource.owner_id
}

output "share_status" {
  description = "Whether the rule is shared with another account, and in which direction."
  value       = aws_route53_resolver_rule.resource.share_status
}
