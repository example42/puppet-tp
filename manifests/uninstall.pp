# @define tp::uninstall
#
# This define uninstalls an application (app) set in the given title.
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
# @param conf_hash                 Default: { } 
#   An hash of tp::conf resources to remove.
#   with ensure absent.
#
# @param dir_hash                  Default: { } 
#   An hash of tp::dir resources to remove.
#
# @param settings_hash             Default: { } 
#   An hash that can override the application settings tp returns, according to the
#   underlying Operating System and the default behaviour
#
# @param auto_repo                 Default: true
#   Boolean to enable automatic package repo management for the specified
#   application. Repo data is not always provided.
#
# @param data_module               Default: 'tinydata'
#   Name of the module where tp data is looked for
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
  and $settings[repo_url] {
    tp::repo { $title:
      enabled => false,
      before  => Package[$settings[package_name]],
    }
  }


  # Resources
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
    create_resources('tp::conf', $conf_hash , { ensure => absent })
  }
  if $dir_hash != {} {
    create_resources('tp::dir', $dir_hash , { ensure => absent })
  }

}
