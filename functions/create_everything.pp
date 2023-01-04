# Function tp::create_everything.
# Gets an hash of resource types and creates the relevant resources
function tp::create_everything (
  Hash $resources = {},
  Hash $resources_defaults = {},
) {
  $resources.each |$resource,$params| {
    case $params {
      Hash: {
        $params.each |$kk,$vv| {
          create_resources($resource, { $kk => {} }, pick(getvar("resources_defaults.${resource}"), $resources_defaults) + $vv)
        }
      }
      Array: {
        create_resources($resource, { $params.unique => {} }, pick(getvar("resources_defaults.${resource}"), $resources_defaults))
      }
      String: {
        create_resources($resource, { $params => {} }, pick(getvar("resources_defaults.${resource}"), $resources_defaults))
      }
      Undef: {
        # do nothing
      }
      default: {
        fail("Unsupported type for ${resource_data}. Valid types are String, Array, Hash, Undef.")
      }
    }
  }
}
