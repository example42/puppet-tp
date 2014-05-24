#
# = Define: tp::dir
#
define tp::dir (

  $source               = undef,

  $path                 = undef,
  $mode                 = undef,
  $owner                = undef,
  $group                = undef,

  $config_dir_notify   = 'class_default',
  $config_dir_require  = undef,

  $purge                = undef,
  $recurse              = undef,
  $force                = undef,

  $options_hash         = undef,

  ) {

  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $dir = $title_elements[1]
  $settings = tp_lookup($app,"settings")

  $manage_path    = tp_pick($path, $settings[config_dir_path])
  $manage_mode    = tp_pick($mode, $settings[config_dir_mode])
  $manage_owner   = tp_pick($owner, $settings[config_dir_owner])
  $manage_group   = tp_pick($group, $settings[config_dir_group])
  $manage_require = tp_pick($config_dir_require, $settings[config_dir_require])
  $manage_notify  = $config_dir_notify ? {
    'class_default' => $settings[config_dir_notify],
    'undef'         => undef,
    ''              => undef,
    default         => $config_dir_notify,
  }

  file { "tp_dir_${manage_path}":
    ensure  => directory,
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

