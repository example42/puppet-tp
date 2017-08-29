# @define tp::uninstall
#
# This define uninstalls the application (app) defined in title.
# It may also remove the relevant repository and configuration files.
#
# @example removal (of any any supported app and OS):
#   tp::uninstall { $app: }
#
# @example remove also configuration file(s) and dirs (DANGER ZONE!)
#   tp::uninstall { 'postfix':
#     conf_hash => $postfix_files,
#     dir_hash  => $postfix_dirs,
#   }
#
# @param conf_hash An hash of tp::conf resources to remove.
#
# @param dir_hash An hash of tp::dir resources to remove.
#
# @param settings_hash An hash that can override the application settings
#   returned by tp according to the underlying OS defaults.
#
# @param auto_repo Boolean to enable automatic package repo management
#   for the specified application. If true, also the relevant app repo is
#   removed.
#
# @param data_module Name of the module where tp data is looked for
#  Default is tinydata: https://github.com/example42/tinydata
#
define tp::uninstall (

  Hash      $conf_hash                 = { } ,
  Hash      $dir_hash                  = { } ,

  Hash      $settings_hash             = { } ,

  Boolean   $auto_repo                 = true,

  String[1] $data_module               = 'tinydata',

  ) {

  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  # Automatic repo management
  if $auto_repo == true
  and ( $settings['repo_url'] or $settings['yum_mirrorlist']) {
    tp::repo { $title:
      enabled => false,
      before  => Package[$settings[package_name]],
    }
  }


  # Resources removed
  if $settings[package_name] {
    ensure_resource( 'package', $settings[package_name], {
      'ensure' => 'absent',
    } )
  }

  if $settings[service_name] {
    ensure_resource( 'service', $settings[service_name], {
      'ensure'  => 'stopped',
      'enable'  => false,
    } )
  }

  if $conf_hash != {} {
    $conf_hash.each |$k,$v| {
      tp::conf { $k:
        ensure => absent,
      }
    }
  }
  if $dir_hash != {} {
    $dir_hash.each |$k,$v| {
      tp::dir { $k:
        ensure => absent,
      }
    }
  }

}
