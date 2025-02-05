package fugue

# Library

resource_types_v0 = resource_types

resource_types = {rt |
  r = input.resources[_]
  rt = r._type
}

resources_by_type = {rt: rs |
  resource_types[rt]
  rs = {ri: r |
    r = input.resources[ri]
    r._type == rt
  }
}

resource_providers = {provider |
  r = input.resources[_]
  provider = r._provider
}

resources(rt) = ret {
  ret = resources_by_type[rt]
} {
  # Make sure we always return something rather than failing when the resource
  # type is not available.
  not resource_types[rt]
  ret = {}
}

allow_resource(resource) = ret {
  ret = {
    "valid": true,
    "id": resource.id,
    "message": "",
    "type": resource._type
  }
}

deny_resource(resource) = ret {
  ret = deny_resource_with_message(resource, "invalid")
}

deny_resource_with_message(resource, message) = ret {
  ret = {
    "valid": false,
    "id": resource.id,
    "message": message,
    "type": resource._type
  }
}

missing_resource(resource_type) = ret {
  ret = missing_resource_with_message(resource_type, "invalid")
}

missing_resource_with_message(resource_type, message) = ret {
  ret = {
    "valid": false,
    "id": "",
    "message": message,
    "type": resource_type
  }
}

report_v0(message, policy) = ret {
  ok := all([p.valid | policy[p]])
  msg := {true: "", false: message}
  ret := {
    "valid": ok,
    "message": msg[ok],
    "resources": policy,
  }
}
