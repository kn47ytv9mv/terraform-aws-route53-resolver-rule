mock_provider "aws" {
}

run "rule_type_invalid_rejected" {
  command = plan

  variables {
    domain_name = "example.internal."
    rule_type   = "SIDEWAYS"
  }

  expect_failures = [var.rule_type]
}

run "target_ip_needs_exactly_one_address" {
  command = plan

  variables {
    domain_name          = "example.internal."
    rule_type            = "FORWARD"
    resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
    target_ips = [{
      ip   = "10.100.0.53"
      ipv6 = "2001:db8::53"
    }]
  }

  expect_failures = [var.target_ips]
}

run "forward_rule_with_two_targets_and_one_vpc" {
  command = plan

  variables {
    domain_name          = "example.internal."
    rule_type            = "FORWARD"
    resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
    target_ips = [
      { ip = "10.100.0.53" },
      { ip = "10.100.0.54" },
    ]
    vpc_ids = ["vpc-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_route53_resolver_rule.resource.target_ip) == 2
    error_message = "One target_ip block should be created per entry in target_ips."
  }

  assert {
    condition     = length(aws_route53_resolver_rule_association.resource) == 1
    error_message = "One association should be created per entry in vpc_ids."
  }

  assert {
    condition     = aws_route53_resolver_rule_association.resource[0].vpc_id == "vpc-0123456789abcdef0"
    error_message = "The association should be keyed by its own vpc_id, not an index."
  }
}

run "system_rule_needs_no_endpoint_or_targets" {
  command = plan

  variables {
    domain_name = "internal-override.example.internal."
    rule_type   = "SYSTEM"
    vpc_ids     = ["vpc-0123456789abcdef0"]
  }

  assert {
    condition     = aws_route53_resolver_rule.resource.resolver_endpoint_id == null
    error_message = "A SYSTEM rule should have no resolver_endpoint_id."
  }

  assert {
    condition     = length(aws_route53_resolver_rule.resource.target_ip) == 0
    error_message = "A SYSTEM rule should have no target_ip blocks."
  }
}

run "readme_forward_example" {
  command = plan

  variables {
    domain_name          = "example.internal."
    rule_type            = "FORWARD"
    resolver_endpoint_id = "rslvr-out-0123456789abcdef0"
    target_ips = [
      { ip = "10.100.0.53" },
      { ip = "10.100.0.54" },
    ]
    vpc_ids = ["vpc-0123456789abcdef0"]
  }
}

run "readme_system_example" {
  command = plan

  variables {
    domain_name = "internal-override.example.internal."
    rule_type   = "SYSTEM"
    vpc_ids     = ["vpc-0123456789abcdef0"]
  }
}
