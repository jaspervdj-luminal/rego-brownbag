package rules.aws.ports_by_account

allowed_ports[443] {
  true
}

allowed_ports[80] {
  account_id != "622401240280"
}
