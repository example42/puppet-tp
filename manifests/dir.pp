#
# = Define: tp::dir
#
define tp::dir (

  $ensure               = 'present',

  $source               = undef,
  $vcsrepo              = undef,

  $dir_type             = 'config',

  $path                 = undef,
  $mode                 = undef,
  $owner                = undef,
  $group                = undef,

  $config_dir_notify    = true,
  $config_dir_require   = true,

  $purge                = undef,
  $recurse              = undef,
  $force                = undef,

  $debug                = false,
  $debug_dir            = '/tmp',

  $data_module          = 'tp',

  ) {

  # Parameters validation
  validate_bool($debug)


  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $dir = $title_elements[1]
  if $title =~ /^\/.*$/ {
    # If title is an absolute path do a safe lookup to
    # a dummy app
    $settings = tp_lookup('test','settings','tp','merge')
    $title_path = $title
  } else {
    $settings = tp_lookup($app,'settings',$data_module,'merge')
  }
  $dir_type_path = $dir_type ? {
    'config' => $settings[config_dir_path],
    'confd'  => $settings[confd_dir_path],
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

