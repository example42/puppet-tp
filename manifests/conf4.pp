# @define tp::conf4
#
# This define is equivalent to tp::conf but is compatible
# only with Puppet 4 or Puppet > 3.7 with future parser enabled
#
# Check documentation of tp::conf for usage and reference.
#
define tp::conf4 (

  String[1]             $ensure              = present,

  Variant[Undef,String] $source              = undef,
  Variant[Undef,String] $template            = undef,
  Variant[Undef,String] $epp                 = undef,
  Variant[Undef,String] $content             = undef,

  String[1]             $base_dir            = 'config',

  Variant[Undef,String] $path                = undef,
  Variant[Undef,String] $mode                = undef,
  Variant[Undef,String] $owner               = undef,
  Variant[Undef,String] $group               = undef,

  Boolean               $config_file_notify  = true,
  Boolean               $config_file_require = true,

  Hash                  $options_hash        = { },
  Hash                  $settings_hash       = { } ,

  Boolean               $debug               = false,
  String[1]             $debug_dir           = '/tmp',

  String[1]             $data_module         = 'tp',

  ) {

  # Sample code for tp lookup for app specific default options 
  # $tp_options = tp_lookup($app,'options',$data_module,'merge')
  # $options = merge($tp_options,$options_hash)
  $options = $options_hash

  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $file = $title_elements[1]
  $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  if $file {
    $real_dir = $settings["${base_dir}_dir_path"]
    $auto_path = "${real_dir}/${file}"
  } else {
    $auto_path = $settings['config_file_path']
  }
  $manage_path    = tp_pick($path, $auto_path)
  $manage_content = tp_content($content, $template, $epp)
  $manage_mode    = tp_pick($mode, $settings[config_file_mode])
  $manage_owner   = tp_pick($owner, $settings[config_file_owner])
  $manage_group   = tp_pick($group, $settings[config_file_group])

  # Set require if package_name is present 
  if $settings[package_name] and $settings[package_name] != '' {
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

  # Set notify if service_name is present 
  if $settings[service_name] and $settings[service_name] != '' {
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


  # Resources
  file { $manage_path:
    ensure  => $ensure,
    source  => $source,
    content => $manage_content,
    path    => $manage_path,
    mode    => $manage_mode,
    owner   => $manage_owner,
    group   => $manage_group,
    require => $manage_require,
    notify  => $manage_notify,
  }


  # Debugging
  if $debug == true {
    $debug_file_params = "
    file { 'tp_conf_${manage_path}':
      ensure  => ${ensure},
      source  => ${source},
      content => ${manage_content},
      path    => ${manage_path},
      mode    => ${manage_mode},
      owner   => ${manage_owner},
      group   => ${manage_group},
      require => ${manage_require},
      notify  => ${manage_notify},
    }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_conf_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_conf_debug_${title}",
    }
  }

}
