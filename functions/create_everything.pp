# Function tp::create_everything.
# Gets an url and coverts is based on a given map
function tp::create_everything (
  Hash $resources = {},
  Hash $resource_defaults = {},
) {
  $resource_defaults = {}
  $resources.each |$resource,$params| {
    case $params {
      Hash: {
        $resource.each |$kk,$vv| {
          create_resources($resource, { $kk => {} }, $resource_defaults + $vv)
        }
      }
      Array: {
        create_resources($resource, { $resource_data.unique => {} }, $resource_defaults)
      }
      String: {
        create_resources($resource, { $resource_data => {} }, $resource_defaults)
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
