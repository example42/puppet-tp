#
# Define tp::repo
#
# Manages a yum/apt repo for an application
#
define tp::repo (

  Boolean                   $enabled             = true,
  Hash                      $settings_hash       = { },

  Variant[Undef,String]     $repo                = undef,
  Variant[Undef,Boolean]    $upstream_repo       = undef,

  String[1]                 $description         = "${title} repository",

  Variant[Undef,String[1]]  $repo_url            = undef,
  Variant[Undef,String[1]]  $key_url             = undef,
  Variant[Undef,String[1]]  $key                 = undef,
  Boolean                   $include_src         = false,

  Variant[Undef,String[1]]  $repo_file_url       = undef,

  Variant[Undef,Integer]    $yum_priority        = undef,
  Variant[Undef,String[1],Boolean] $yum_gpgcheck = undef,
  Variant[Undef,String[1]] $yum_mirrorlist       = undef,

  Variant[Undef,String[1]] $apt_key_server       = undef,
  Variant[Undef,String[1]] $apt_key_fingerprint  = undef,
  Variant[Undef,String[1]] $apt_release          = undef,
  Variant[Undef,String[1]] $apt_repos            = undef,
  Variant[Undef,String[1]] $apt_pin              = undef,

  Variant[Undef,String[1]] $zypper_repofile_url  = undef,

  Array                    $exec_environment     = [],

  Boolean                  $debug                = false,
  Stdlib::Absolutepath     $debug_dir            = '/tmp',
  Stdlib::Absolutepath     $download_dir         = '/var/tmp',

  String[1]                $data_module          = 'tinydata',

) {

  # Settings evaluation
  $enabled_num = bool2num($enabled)
  $ensure      = bool2ensure($enabled)
  $tp_settings = tp_lookup($title,'settings',$data_module,'merge')
  $user_settings = {
    repo_url            => $repo_url,
    key_url             => $key_url,
    key                 => $key,
    include_src         => $include_src,
    apt_key_server      => $apt_key_server,
    apt_key_fingerprint => $apt_key_fingerprint,
    apt_release         => $apt_release,
    apt_repos           => $apt_repos,
    apt_pin             => $apt_pin,
    yum_priority        => $yum_priority,
    yum_mirrorlist      => $yum_mirrorlist,
    zypper_repofile_url => $zypper_repofile_url,
  }
  $user_settings_clean = delete_undef_values($user_settings)
  $settings = $tp_settings + $settings_hash + $user_settings_clean

  $manage_yum_gpgcheck = $yum_gpgcheck ? {
    undef   => $settings[key_url] ? {
      undef   => '0',
      default => '1',
    },
    default => $yum_gpgcheck,
  }

  # Refreshable execs
  if !defined(Exec['tp_apt_update'])
  and ( $::osfamily == 'Debian' ) {
    exec { 'tp_apt_update':
      command     => '/usr/bin/apt-get -qq update',
      path        => '/bin:/sbin:/usr/bin:/usr/sbin',
      logoutput   => false,
      refreshonly => true,
      environment => $exec_environment,
    }
  }

  if !defined(Exec['zypper refresh'])
  and ( $::osfamily == 'Suse' ) {
    exec { 'zypper refresh':
      command     => 'zypper refresh',
      path        => '/bin:/sbin:/usr/bin:/usr/sbin',
      logoutput   => false,
      refreshonly => true,
      environment => $exec_environment,
    }
  }

  # Install repo via release package, if tinydata present
  if $settings[repo_package_url] and $settings[repo_package_name] {
    if ! defined(Package[$settings[repo_package_name]]) {
      $repo_package_before = $settings[package_name] ? {
        ''      => undef,
        undef   => undef,
        default => Package[$settings[package_name]],
      }
      case $::osfamily {
        'Debian': {
          $repo_package_path = "${download_dir}/${settings[repo_package_name]}"
          exec { "Download ${title} release package":
            command     => "wget -O ${repo_package_path} '${settings[repo_package_url]}'",
            before      => Package[$settings[repo_package_name]],
            creates     => $repo_package_path,
            path        => '/bin:/sbin:/usr/bin:/usr/sbin',
            environment => $exec_environment,
          }
          $package_params = {
            source   => $repo_package_path,
            provider => pick($settings[repo_package_provider],'dpkg'),
            before   => $repo_package_before,
          }
        }
        default: {
          $package_params = {
            source   => $settings[repo_package_url],
            provider => $settings[repo_package_provider],
            before   => $repo_package_before,
          }
        }
      }
      package { $settings[repo_package_name]:
        * => $package_params + pick($settings[repo_package_params],{})
      }
    }
  } else {

    # If not release package is available, repos are managed with OS dependent resources
    case $::osfamily {
      'Suse': {
        if !empty($settings[zypper_repofile_url]) {
          $zypper_command = "zypper -n addrepo ${settings[zypper_repofile_url]}"
          $zypper_unless = "zypper repos  | grep ${settings[repo_name]}"
        } else {
          $zypper_command = "zypper -n addrepo ${settings[repo_url]} ${settings[repo_name]}"
          $zypper_unless = "zypper repos -u | grep ${settings[repo_url]}"
        }
        if !defined(Exec["zypper_addrepo_${title}"]) {
          exec { "zypper_addrepo_${title}":
            command     => $zypper_command,
            unless      => $zypper_unless,
            notify      => Exec['zypper refresh'],
            path        => '/bin:/sbin:/usr/bin:/usr/sbin',
            environment => $exec_environment,
          }
        }
      }
      'RedHat': {
        $yumrepo_title = pick($settings[repo_filename],$title)
        $yumrepo_description = pick($settings[repo_description],$description)
        if !defined(Yumrepo[$yumrepo_title])
        and ( $settings[repo_url] or $settings[yum_mirrorlist] ) {
          yumrepo { $yumrepo_title:
            enabled    => $enabled_num,
            descr      => $yumrepo_description,
            baseurl    => $settings[repo_url],
            gpgcheck   => $manage_yum_gpgcheck,
            gpgkey     => $settings[key_url],
            priority   => $settings[yum_priority],
            mirrorlist => $settings[yum_mirrorlist],
          }
        }
      }
      # To avoid to introduce another dependency we manage apt repos directly
      'Debian': {
        if !empty($settings[package_name])
        and !empty($settings[key])
        and defined(Package[$settings[package_name]]) {
          Exec['tp_apt_update'] -> Package[$settings[package_name]]
        }

        $aptrepo_title = pick($settings[repo_filename],$title)
        if !defined(File["${aptrepo_title}.list"])
        and !empty($settings[key])
        and !empty($settings[key_url])
        and !empty($settings[repo_url]) {
          file { "${aptrepo_title}.list":
            ensure  => $ensure,
            path    => "/etc/apt/sources.list.d/${aptrepo_title}.list",
            owner   => root,
            group   => root,
            mode    => '0644',
            content => template('tp/apt/source.list.erb'),
            notify  => Exec['tp_apt_update'],
          }
        }

        if !defined(Exec["tp_aptkey_add_${settings[key]}"])
        and !empty($settings[key])
        and !empty($settings[key_url]) {
          exec { "tp_aptkey_add_${settings[key]}":
            command     => "wget -O - ${settings[key_url]} | apt-key add -",
            unless      => "apt-key list | grep -q \"${settings[key]}\"",
            path        => '/bin:/sbin:/usr/bin:/usr/sbin',
            before      => File["${aptrepo_title}.list"],
            user        => 'root',
            environment => $exec_environment,
          }
        }

        if !defined(Exec["tp_aptkey_adv_${settings[key]}"])
        and !empty($settings[key])
        and !empty($settings[apt_key_fingerprint])
        and !empty($settings[apt_key_server]) {
          exec { "tp_aptkey_adv_${settings[key]}":
            command     => "apt-key adv --keyserver ${settings[apt_key_server]} --recv ${settings[apt_key_fingerprint]}",
            unless      => "apt-key list | grep -q \"${settings[key]}\"",
            path        => '/bin:/sbin:/usr/bin:/usr/sbin',
            before      => File["${aptrepo_title}.list"],
            user        => 'root',
            environment => $exec_environment,
          }
        }

      }
      default: {
        notify { "No repo for ${title}":
          message =>"No dedicated repo available for ${::osfamily}",
        }
      }
    }
  }

  if !empty($settings[repo_file_url]) {
    $repo_file_name = pick($settings['repo_filename'],$title)
    $repo_file_path = $::osfamily ? {
      'Debian' => "/etc/apt/sources.list.d/${repo_file_name}.list",
      'RedHat' => "/etc/yum.repos.d/${repo_file_name}.repo",
      'Suse'   => "/etc/zypp/repos.d/${repo_file_name}.repo",
    }
    $repo_file_notify = $::osfamily ? {
      'Debian' => 'Exec["tp_apt_update"]',
      'RedHat' => undef,
      'Suse'   => 'Exec["zypper refresh"]',
    }
    file { $repo_file_path:
      ensure => $ensure,
      path   => $repo_file_path,
      owner  => root,
      group  => root,
      mode   => '0644',
      source => $repo_file_url,
      notify => $repo_file_notify,
    }
  }
  # Debugging
  if $debug == true {
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    file { "tp_repo_debug_${title}":
      ensure  => present,
      content => $debug_scope,
      path    => "${debug_dir}/tp_repo_debug_${title}",
    }
  }
}
