package rules.aws.ports_by_account

allowed_ports[443] = "https" {
  true
}

allowed_ports[80] = "http" {
  account_id != "622401240280"
}
