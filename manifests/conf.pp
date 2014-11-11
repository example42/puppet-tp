#
# = Define: tp::conf
#
define tp::conf (

  $source               = undef,
  $template             = undef,
  $epp                  = undef,
  $content              = undef,

  $path                 = undef,
  $mode                 = undef,
  $owner                = undef,
  $group                = undef,

  $config_file_notify   = 'default',
  $config_file_require  = undef,

  $options_hash         = undef,

  $ensure               = present,

  ) {

  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent. WARNING: If set to absent the conf file is removed.')

  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $file = $title_elements[1]
  $settings = tp_lookup($app,'settings','merge')
  $auto_path = $file ? {
    undef   => $settings[config_file_path],
    default => "${settings[config_dir_path]}/${file}",
  }
  $manage_path    = tp_pick($path, $auto_path)
  $manage_content = tp_content($content, $template, $epp)
  $manage_mode    = tp_pick($mode, $settings[config_file_mode])
  $manage_owner   = tp_pick($owner, $settings[config_file_owner])
  $manage_group   = tp_pick($group, $settings[config_file_group])
  $manage_require = $settings[package_name] ? {
    'undef'   => undef,
    ''        => undef,
    default   => "Package[${settings[package_name]}]"
  }
  $manage_notify  = $config_file_notify ? {
    'default' => "Service[${settings[service_name]}]",
    'undef'   => undef,
    ''        => undef,
    default   => $config_file_notify,
  }

  file { "tp_conf_${manage_path}":
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

}
