# @summary Setups an application from source build or release tarball
#
# This defines setups an application copying files to target locations,
# eventually configuring the relevant service and user
#
# @example
#   tp::setup { 'namevar': }
define tp::setup (
  Tp::Install_method $install_method,
  String $app,
  Optional[StdLib::Absolutepath] $source_dir = undef,
  Variant[Boolean,String] $ensure             = present,
  Optional[String] $version  = undef,
  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),
  Hash $settings                              = {},

  String[1] $owner = pick(getvar('identity.user'),'root'),
  String[1] $group = pick(getvar('identity.group'),'root'),
) {
  $destination_dir = $tp::real_tp_params['destination']['path']

  # Setup settings are a result from the merge of keys settings.$install_method.setup and settings.setup
  $setup_settings = deep_merge(getvar('settings.setup', {}),getvar("settings.${install_method}.setup", {}))

  $real_version = tp::get_version($ensure,$version,$setup_settings)
  $real_majversion = tp::get_version($ensure,$version,$setup_settings,'major')

  if pick(getvar('setup_settings.enable'), false ) {
    if pick(getvar('setup_settings.manage_service'), false ) {
      $before_tp_service = Tp::Service[$app]
      tp::service { $app:
        ensure          => $ensure,
        on_missing_data => $on_missing_data,
        settings        => $settings,
        my_options      => getvar('setup_settings.systemd_options', {}),
        systemd_symlink => pick_default(getvar('setup_settings.systemd_symlink')),
      }
    } else {
      $before_tp_service = undef
    }

    $files = getvar('setup_settings.files', {})
    if $source_dir {
      case $files {
        Hash: {
          $files.each | $k,$v | {
            tp::copy_file { $k:
              ensure => pick($v['ensure'],$ensure),
              path   => pick($v['path'], "${destination_dir}/${k}"),
              owner  => pick($v['owner'], $owner),
              group  => pick($v['group'], $group),
              mode   => pick($v['mode'], '0755'),
              source => pick($v['source'],"${source_dir}/${k}"),
              before => $before_tp_service,
            }
          }
        }
        Array: {
          $files.each | $k | {
            tp::copy_file { "${destination_dir}/${k}":
              ensure => $ensure,
              path   => "${destination_dir}/${k}",
              owner  => $owner,
              group  => $group,
              source => "${source_dir}/${k}",
              mode   => '0755',
              before => $before_tp_service,
            }
          }
        }
        String: {
          tp::copy_file { "${destination_dir}/${files}":
            ensure => $ensure,
            path   => "${destination_dir}/${files}",
            owner  => $owner,
            group  => $group,
            source => "${source_dir}/${files}",
            mode   => '0755',
            before => $before_tp_service,
          }
        }
        default: {
          tp::fail($on_missing_data, "tp::setup ${app} - Missing tinydata: settings.setup.files or settings.${install_method}.setup.files is not a Hash, Array or String") # lint:ignore:140chars
        }
      }
    }

    $links = getvar('setup_settings.links', {})
    $links.each | $k,$v | {
      file { $k:
        ensure => link,
        target => tp::url_replace($v,$real_version,$real_majversion),
        before => $before_tp_service,
      }
    }

    if pick(getvar('setup_settings.manage_user'), false) and getvar('setup_settings.process_user') {
      user { getvar('setup_settings.process_user'):
        ensure     => $ensure,
        managehome => true,
        before     => $before_tp_service,
      }
    }

    if getvar('setup_settings.resources') and $ensure != 'absent' {
      tp::create_everything ( getvar('setup_settings.resources'), { 'before' => $before_tp_service })
    }
  }
}
