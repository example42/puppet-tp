#
# = Define: tp::augeas
#
define tp::augeas (

  $ensure               = present,

  $context              = undef,
  $changes              = undef,
  $onlyif               = undef,
  $force                = undef,
  $incl                 = undef,
  $lens                 = undef,
  $load_path            = undef,
  $onlyif               = undef,
  $returns              = undef,
  $root                 = undef,
  $show_diff            = undef,
  $type_check           = undef,

  $config_file_notify   = true, # If Package[$title] exists, require it
  $config_file_require  = true, # If Service[$title] exists, notify it

  $debug                = false,
  $debug_dir            = '/tmp',

  $data_module          = 'tp',

  ) {

  # Parameters validation
  validate_bool($debug)
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent. WARNING: If set to absent the conf file is removed.')


  # Settings evaluation
  $title_elements = split($title,'::')
  $app = $title_elements[0]
  $fragment = $title_elements[1]
  $settings = tp_lookup($app,'settings',$data_module,'merge')
  $manage_context = tp_pick($context, $settings['config_file_path'])

  # Set require if package resource is present
  if defined("Package[${settings[package_name]}]") {
    $package_ref = "Package[${settings[package_name]}]"
  } else {
    $package_ref = undef
  }
  $manage_require = $config_file_require ? {
    ''        => undef,
    false     => undef,
    true      => $package_ref,
    default   => $config_file_require,
  }

  # Set notify if service resource is present
  if defined("Service[${settings[service_name]}]") {
    $service_ref = "Service[${settings[service_name]}]"
  } else {
    $service_ref = undef
  }
  $manage_notify  = $config_file_notify ? {
    ''        => undef,
    false     => undef,
    true      => $service_ref,
    default   => $config_file_notify,
  }


  if !defined(Augeas[$manage_path]) {
    ::augeas { $manage_path:
      context    => undef,
      changes    => undef,
      onlyif     => undef,
      force      => undef,
      incl       => undef,
      lens       => undef,
      load_path  => undef,
      onlyif     => undef,
      returns    => undef,
      root       => undef,
      show_diff  => undef,
      type_check => undef,

      require    => $manage_require,
      notify     => $manage_notify,
    }
  }

}
