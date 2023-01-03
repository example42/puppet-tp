# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   tp::build { 'namevar': }
define tp::build (
  Stdlib::Absolutepath $build_dir,
  Variant[Boolean,String] $ensure             = present,
  Tp::Fail $on_missing_data    = pick(getvar('tp::on_missing_data'),'notify'),
  Hash $settings                              = {},
  String[1] $data_module                      = 'tinydata',
  Boolean $auto_prereq                        = pick(getvar('tp::auto_prereq'), false),
  Optional[Boolean] $build                    = undef,
  Optional[Boolean] $install                  = undef,
  Optional[Boolean] $manage_user              = undef,

  String[1] $owner = pick(getvar('identity.user'),'root'),
  String[1] $group = pick(getvar('identity.group'),'root'),
) {
  include tp
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')
  $destination_dir = $tp::real_tp_params['destination']['path']
  $flags_dir = $tp::flags_dir

  if pick($build, getvar('settings.build.enable'), false ) {
    if $auto_prereq and getvar('settings.build.prerequisites') {
      tp::create_everything ( getvar('settings.build.prerequisites'), {})
    }
    if getvar('settings.build.execs') {
      getvar('settings.build.execs').each | $c,$v | {
        if getvar('v.creates') =~ Undef
        and getvar('v.unless') =~ Undef
        and getvar('v.onlyif') =~ Undef {
          $creates_suffix = " && touch ${flags_dir}/${app}_${c}"
          $creates        = "${flags_dir}/${app}_${c}"
        } else {
          $creates_suffix = ''
          $creates = undef
        }
        $default_exec_params = {
          'cwd'         => $build_dir,
          path          => $facts['path'],
          creates       => $creates,
        }
        exec { "${app} - tp::build exec - ${c}":
          * => $default_exec_params + $v + {
            command => "${v['command']}${creates_suffix}",
          },
        }
      }
    }
  }

  if pick($install, getvar('settings.install.enable'), false ) {
    $files = getvar('settings.install.files', {})
    case $files {
      Hash: {
        $files.each | $k,$v | {
          file { $k:
            ensure => pick($v['ensure'],$ensure),
            path   => pick($v['path'], "${destination_dir}/${k}"),
            owner  => pick($v['owner'], $owner),
            group  => pick($v['group'], $group),
            mode   => pick($v['mode'], '0755'),
            source => pick($v['source'],"file://${build_dir}/${k}"),
          }
        }
      }
      Array: {
        $files.each | $k | {
          file { "${destination_dir}/${k}":
            ensure => $ensure,
            path   => "${destination_dir}/${k}",
            owner  => $owner,
            group  => $group,
            source => "file://${build_dir}/${k}",
            mode   => '0755',
          }
        }
      }
      String: {
        file { "${destination_dir}/${files}":
          ensure => $ensure,
          path   => "${destination_dir}/${files}",
          owner  => $owner,
          group  => $group,
          source => "file://${build_dir}/${files}",
          mode   => '0755',
        }
      }
      default: {
        tp::fail($on_missing_data, 'tp::build missing tinydata: settings.install.files is not a Hash, Array or String') # lint:ignore:140chars
      }
    }

    if pick($manage_user, getvar('settings.install.manage_user'), false) and getvar('settings.process_user') {
      user { getvar('settings.process_user'):
        ensure     => $ensure,
        managehome => true,
      }
    }

    if getvar('settings.install.resources') and $ensure != 'absent' {
      tp::create_everything ( getvar('settings.install.resources'), {})
    }
  }
}
