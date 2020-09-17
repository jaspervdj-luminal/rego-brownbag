package rules.aws.ports_by_account

account_id = ret {
  # "arn:aws:ec2:REGION:ACCOUNT_ID:security-group/RESOURCE_ID"
  parts = split(input.arn, ":")
  ret = parts[4]
}
