# @define tp::uninstall3
#
# This define uninstalls an application (app) set in the given title.
#
# @example removal (of any any supported app and OS):
#   tp::uninstall3 { $app: }
#
# @example remove also configuration file(s) and dirs (DANGER ZONE!)
#   tp::uninstall3 { 'postfix':
#     conf_hash => $postfix_files,
#     dir_hash  => $postfix_dirs,
#   }
#
# @param conf_hash                 Default: { } 
#   An hash of tp::conf3 resources to remove.
#   with ensure absent.
#
# @param dir_hash                  Default: { } 
#   An hash of tp::dir3 resources to remove.
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
define tp::uninstall3 (

  $conf_hash                 = { } ,
  $dir_hash                  = { } ,

  $settings_hash             = { } ,

  $auto_repo                 = true,

  $data_module               = 'tinydata',

  ) {

  # Parameters validation
  validate_bool($auto_repo)
  validate_hash($conf_hash)
  validate_hash($dir_hash)
  validate_hash($settings_hash)


  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings=merge($tp_settings,$settings_hash)

  # Automatic repo management
  if $auto_repo == true
  and $settings[repo_url] {
    tp::repo3 { $title:
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
    create_resources('tp::conf3', $conf_hash , { ensure => absent })
  }
  if $dir_hash != {} {
    create_resources('tp::dir3', $dir_hash , { ensure => absent })
  }

}
