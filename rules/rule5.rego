package rules.aws.ports_by_account

import data.fugue

valid_ingress(ingress) {
  ingress.from_port == ingress.to_port
}

security_groups = fugue.resources("aws_security_group")

policy[j] {
  sg = security_groups[_]
  valid_ingress(sg)
  j = fugue.allow_resource(sg)
}

policy[j] {
  sg = security_groups[_]
  not valid_ingress(sg)
  j = fugue.deny_resource(sg)
}
