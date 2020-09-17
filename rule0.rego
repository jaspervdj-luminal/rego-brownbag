package rules.aws.ports_by_account

resource_type = "aws_security_group"

allowed_ports[443] {
  true
}
