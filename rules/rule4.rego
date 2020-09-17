package rules.aws.ports_by_account

valid_ingress(ingress) {
  ingress.from_port == ingress.to_port
}

default deny = false

deny {
  ingress = input.ingress[_]
  not valid_ingress(ingress)
}
