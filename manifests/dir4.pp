# @define tp::dir4
#
# This define is equivalent to tp::dir but is compatible
# only with Puppet 4 or Puppet >= 3.7 with future parser enabled
#
# Check documentation of tp::dir for usage and reference.
#
define tp::dir4 (

  String $ensure              = 'present',

  Any $source                 = undef,
  Any $vcsrepo                = undef,
 
  String $dir_type            = 'config',

  Any $path                   = undef,
  Any $mode                   = undef,
  Any $owner                  = undef,
  Any $group                  = undef,

  Boolean $config_dir_notify  = true,
  Boolean $config_dir_require = true,

  Any $purge                  = undef,
  Any $recurse                = undef,
  Any $force                  = undef,

  Hash $settings_hash         = { } ,

  Boolean $debug              = false,
  String $debug_dir           = '/tmp',

  String $data_module         = 'tp',

  ) {

  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $dir = $title_elements[1]
  if $title =~ /^\/.*$/ {
    # If title is an absolute path do a safe lookup to
    # a dummy app
    $tp_settings = tp_lookup('test','settings','tp','merge')
    $title_path = $title
  } else {
    $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  }
  $settings = $tp_settings + $settings_hash

  # TODO: Find a sane and general purpose approach (Puppet 3 compatible)
  $dir_type_path = $dir_type ? {
  # $dir_type_path = $dir ? {
    'config' => $settings[config_dir_path],
    'conf'   => $settings[conf_dir_path],
    'log'    => $settings[log_dir_path],
    'data'   => $settings[data_dir_path],
    default  => undef,
  }
  $manage_path    = tp_pick($path, $title_path, $dir_type_path)
  $manage_mode    = tp_pick($mode, $settings[config_dir_mode])
  $manage_owner   = tp_pick($owner, $settings[config_dir_owner])
  $manage_group   = tp_pick($group, $settings[config_dir_group])

  # Set require if package_name is present 
  if $settings[package_name] and $settings[package_name] != '' {
    $package_ref = "Package[${settings[package_name]}]"
  } else {
    $package_ref = undef
  }
  $manage_require = $config_dir_require ? {
    ''        => undef,
    false     => undef,
    true      => $package_ref,
    default   => $config_dir_require,
  }

  # Set notify if service_name is present 
  if $settings[service_name] and $settings[package_name] != '' {
    $service_ref = "Service[${settings[service_name]}]"
  } else {
    $service_ref = undef
  }
  $manage_notify  = $config_dir_notify ? {
    ''        => undef,
    false     => undef,
    true      => $service_ref,
    default   => $config_dir_notify,
  }

  $manage_ensure = $ensure ? {
    'present' => $vcsrepo ? {
      undef   => 'directory',
      default => 'present',
    },
    'absent' => 'absent',
  }

  # Finally, the resources managed
  if $vcsrepo {
    vcsrepo { $manage_path:
      ensure   => $manage_ensure,
      source   => $source,
      provider => $vcsrepo,
      owner    => $manage_owner,
      group    => $manage_group,
    }
  } else {
    file { $manage_path:
      ensure  => $manage_ensure,
      source  => $source,
      path    => $manage_path,
      mode    => $manage_mode,
      owner   => $manage_owner,
      group   => $manage_group,
      require => $manage_require,
      notify  => $manage_notify,
      recurse => $recurse,
      purge   => $purge,
      force   => $force,
    }
  }


  # Debugging
  if $debug == true {
    $debug_file_params = "
    vcsrepo { ${manage_path}:
      ensure   => ${manage_ensure},
      source   => ${source},
      provider => ${vcsrepo},
      owner    => ${manage_owner},
      group    => ${manage_group},
    }

    file { ${manage_path}:
      ensure  => ${manage_ensure},
      source  => ${source},
      path    => ${manage_path},
      mode    => ${manage_mode},
      owner   => ${manage_owner},
      group   => ${manage_group},
      require => ${manage_require},
      notify  => ${manage_notify},
      recurse => ${recurse},
      purge   => ${purge},
    }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_dir_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_dir_debug_${title}",
    }
  }

}

