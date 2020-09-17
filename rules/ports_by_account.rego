package rules.aws.ports_by_account

resource_type = "aws_security_group"

account_id = ret {
  # "arn:aws:ec2:REGION:ACCOUNT_ID:security-group/RESOURCE_ID"
  parts = split(input.arn, ":")
  ret = parts[4]
}

# Port 443 is always allowed.
allowed_ports[443] {
  true
}

# Port 80 is not allowed in the production account.
allowed_ports[80] {
  account_id != "622401240280"  # Production, replace this.
}

# You can add more logic for further `allowed_ports` here.
# allowed_ports[8080] {
#   account_id == "111111111111"  # Staging
# }

# Check if an ingress block allows ingress from anywhere.
ingress_cidr_wildcard(ingress) {
  ingress.cidr_blocks[_] == "0.0.0.0/0"
} {
  ingress.ipv6_cidr_blocks[_] == "::/0"
}

# Check if an ingress block is valid.  It is valid if either:
# 1. It does not allow ingress from 0.0.0.0/0
# 2. It allows ingress from a specific port which is in `allowed_ports`
valid_ingress(ingress) {
  not ingress_cidr_wildcard(ingress)
} {
  ingress.from_port == ingress.to_port
  allowed_ports[_] == ingress.from_port
}

# A security group has a list of ingress blocks.  We want to deny the
# resource if _any_ of the ingress blocks is not valid.
default deny = false
deny {
  ingress = input.ingress[_]
  not valid_ingress(ingress)
}

# Task 1: try to uncomment this and take it into account:
#
#     extra_ports_by_stage = {
#       "prod": [9001, 9002]
#       "staging": [9001]
#     }
#
# remember that you can always evaluate `allowed_ports` in `fregot repl`.

# Task 2: can we make `deny` return an error message that is nicer?
#
# We need a set definition of `deny`:
#
#     deny[msg] {
#         msg = "boo"
#     }
#
# Check the OPA reference for printing functions!
# <https://www.openpolicyagent.org/docs/latest/policy-reference/#built-in-functions>
