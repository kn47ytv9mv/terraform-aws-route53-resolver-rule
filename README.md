# terraform-aws-route53-resolver-rule

Terraform module for a Route53 Resolver forwarding rule and its VPC
associations.

## Cost

No cost impact of its own — queries the rule forwards are billed on the
outbound resolver endpoint it forwards through. See
[`terraform-aws-route53-resolver-endpoint`](https://github.com/kn47ytv9mv/terraform-aws-route53-resolver-endpoint)'s
Cost section.

## Design

A `'FORWARD'` rule sends DNS queries matching `domain_name` out through an
`'OUTBOUND'` resolver endpoint to `target_ips` — typically on-premises DNS
servers, for a hybrid network where those servers are authoritative for
some internal zone. VPC associations (`vpc_ids`) are bundled into this
module rather than split out, the same way
[`terraform-aws-transit-gateway-route-table`](https://github.com/kn47ytv9mv/terraform-aws-transit-gateway-route-table)
bundles its associations — nothing outside this module ever needs to
reference one specific association by its own ID.

A rule with no VPC associated with it has no effect; a query is only
evaluated against this rule from within a VPC listed in `vpc_ids`.

### Why these are addressed by position

**Rule associations are addressed by their position in the list, not by the
VPC ID itself.** Terraform has to know every `for_each` key before it
plans, and a VPC created in the same apply has no ID yet, so keying
on it fails with *"the for_each set includes values derived from resource
attributes that cannot be determined until apply"* — which rules out the
ordinary case of building both together. A list's length is known even
when none of its elements are, so `count` plans cleanly.

The consequence worth knowing: **reordering or removing an entry shifts
every later one's address**, and Terraform will plan to destroy and
recreate them. Append rather than insert, and use `moved` blocks when an
existing deployment has to be reshuffled.

## Usage

```hcl
module "resolver_rule" {
  source = "kn47ytv9mv/route53-resolver-rule/aws"

  domain_name          = "example.internal."
  rule_type            = "FORWARD"
  resolver_endpoint_id = module.resolver_outbound.id

  target_ips = [
    { ip = "10.100.0.53" },
    { ip = "10.100.0.54" },
  ]

  vpc_ids = [module.vpc.vpc_id]
}
```

Or directly from this repository:

```hcl
module "resolver_rule" {
  source = "github.com/kn47ytv9mv/terraform-aws-route53-resolver-rule"

  domain_name = "internal-override.example.internal."
  rule_type   = "SYSTEM"
  vpc_ids     = [module.vpc.vpc_id]
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.3 |
| aws | ~> 6.61 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| domain_name | DNS domain name this rule forwards queries for (e.g. `'example.internal.'` for an on-premises zone). | `null` | no |
| rule_type | Rule type: `'FORWARD'` (send matching queries to `target_ips`, requires `resolver_endpoint_id`), `'SYSTEM'` (use AWS's own resolution, overriding a broader forwarding rule for a specific subdomain), or `'RECURSIVE'`. | `null` | no |
| resolver_endpoint_id | The ID of an `'OUTBOUND'` `terraform-aws-route53-resolver-endpoint` to forward queries through. Required for `rule_type = 'FORWARD'`; must be left null for every other `rule_type`. | `null` | no |
| target_ips | DNS servers to forward matching queries to, for `rule_type = 'FORWARD'`. Each entry needs `ip` or `ipv6`; `port` defaults to `53` and `protocol` to `'Do53'` if left unset on that entry. | `[]` | no |
| vpc_ids | IDs of the VPCs this rule applies to. | `[]` | no |
| tags | A map of tags to assign to the resolver rule. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the resolver rule. |
| arn | The ARN of the resolver rule. |
| owner_id | AWS account ID that owns the rule. |
| share_status | Whether the rule is shared with another account, and in which direction. |

## License

MIT — see [LICENSE.md](LICENSE.md).
