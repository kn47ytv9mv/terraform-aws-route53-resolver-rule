variable "domain_name" {
  default     = null
  description = "DNS domain name this rule forwards queries for (e.g. 'example.internal.' for an on-premises zone)."
}

variable "rule_type" {
  default     = null
  description = "Rule type: 'FORWARD' (send matching queries to target_ips, requires resolver_endpoint_id), 'SYSTEM' (use AWS's own resolution, overriding a broader forwarding rule for a specific subdomain), or 'RECURSIVE'."

  validation {
    condition     = var.rule_type == null || contains(["FORWARD", "SYSTEM", "RECURSIVE"], var.rule_type)
    error_message = "rule_type must be 'FORWARD', 'SYSTEM', or 'RECURSIVE'."
  }
}

variable "resolver_endpoint_id" {
  default     = null
  description = "The ID of an 'OUTBOUND' terraform-aws-route53-resolver-endpoint to forward queries through. Required for rule_type = 'FORWARD'; must be left null for every other rule_type."
}

variable "target_ips" {
  default     = []
  description = "DNS servers to forward matching queries to, for rule_type = 'FORWARD'. Each entry needs ip or ipv6; port defaults to 53 and protocol to 'Do53' if left unset on that entry."
  type = list(object({
    ip       = optional(string)
    ipv6     = optional(string)
    port     = optional(number)
    protocol = optional(string)
  }))

  validation {
    condition     = alltrue([for t in var.target_ips : (t.ip != null) != (t.ipv6 != null)])
    error_message = "Each target_ips entry needs exactly one of ip or ipv6."
  }
}

variable "vpc_ids" {
  default     = []
  description = "IDs of the VPCs this rule applies to."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the resolver rule."
}
