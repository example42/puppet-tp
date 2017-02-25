#
# Define tp::repo
#
# Manages a yum/apt repo for an application
#
define tp::repo (

  Boolean                   $enabled             = true,

  Variant[Undef,String]     $repo                = undef,

  String[1]                 $description         = "${title} repository",

  Variant[Undef,String[1]]  $repo_url            = undef,
  Variant[Undef,String[1]]  $key_url             = undef,
  Variant[Undef,String[1]]  $key                 = undef,
  Boolean                   $include_src         = false,

  Variant[Undef,Integer]    $yum_priority        = undef,
  Variant[Undef,String[1],Boolean] $yum_gpgcheck        = undef,
  Variant[Undef,String[1]] $yum_mirrorlist      = undef,

  Variant[Undef,String[1]] $apt_key_server      = undef,
  Variant[Undef,String[1]] $apt_key_fingerprint = undef,
  Variant[Undef,String[1]] $apt_release         = undef,
  Variant[Undef,String[1]] $apt_repos           = undef,
  Variant[Undef,String[1]] $apt_pin             = undef,

  Variant[Undef,String[1]] $zypper_repofile_url = undef,

  Boolean                  $debug               = false,
  String[1]                $debug_dir           = '/tmp',

  String[1]                $data_module         = 'tinydata',

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
  $settings = $tp_settings + $user_settings_clean

  $manage_yum_gpgcheck = $yum_gpgcheck ? {
    undef   => $settings[key_url] ? {
      undef   => '0',
      default => '1',
    },
    default => $yum_gpgcheck,
  }


  # Resources
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
          command => $zypper_command,
          unless  => $zypper_unless,
          notify  => Exec['zypper refresh'],
          path    => '/bin:/sbin:/usr/bin:/usr/sbin',
        }
      }
      if !defined(Exec['zypper refresh']) {
        exec { 'zypper refresh':
          command     => 'zypper refresh',
          path        => '/bin:/sbin:/usr/bin:/usr/sbin',
          logoutput   => false,
          refreshonly => true,
        }
      }
    }
    'RedHat': {
      if !defined(Yumrepo[$title])
      and ( $settings[repo_url] or $settings[yum_mirrorlist] ){
        yumrepo { $title:
          enabled    => $enabled_num,
          descr      => $description,
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
      if !defined(Exec['tp_apt_update'])
      and $settings[package_name] =~ String[0]
      and is_string($settings[key]) {
        exec { 'tp_apt_update':
          command     => '/usr/bin/apt-get -qq update',
          path        => '/bin:/sbin:/usr/bin:/usr/sbin',
          logoutput   => false,
          refreshonly => true,
        }
      }

      if is_string($settings[package_name])
      and $settings[package_name] != ''
      and $settings[package_name] != undef
      and is_string($settings[key]) {
        Exec['tp_apt_update'] -> Package[$settings[package_name]]
      }

      if !defined(File["${title}.list"])
      and !empty($settings[key]) {
        file { "${title}.list":
          ensure  => $ensure,
          path    => "/etc/apt/sources.list.d/${title}.list",
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
          command => "wget -O - ${settings[key_url]} | apt-key add -",
          unless  => "apt-key list | grep -q ${settings[key]}",
          path    => '/bin:/sbin:/usr/bin:/usr/sbin',
          before  => File["${title}.list"],
          user    => 'root',
        }
      }

      if !defined(Exec["tp_aptkey_adv_${settings[key]}"])
      and !empty($settings[key])
      and !empty($settings[apt_key_server]) {
        exec { "tp_aptkey_adv_${settings[key]}":
          command => "apt-key adv --keyserver ${settings[apt_key_server]} --recv ${settings[apt_key_fingerprint]}",
          unless  => "apt-key list | grep -q ${settings[key]}",
          path    => '/bin:/sbin:/usr/bin:/usr/sbin',
          before  => File["${title}.list"],
          user    => 'root',
        }
      }

    }
    default: {
      notify { "No repo for ${title}":
        message =>"No dedicated repo available for ${::osfamily}",
      }
    }
  }

  # Install repo via release package, if tinydata present
  if $settings[repo_package_url] and $settings[repo_package_name] {
    if ! defined(Package[$settings[repo_package_name]]) {
      package { $settings[repo_package_name]:
        source   => $settings[repo_package_url],
        provider => $settings[repo_package_provider],
        before   => Package[$settings[package_name]],
      }
    }
  }

  if $debug == true {
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    file { "tp_repo_debug_${title}":
      ensure  => present,
      content => $debug_scope,
      path    => "${debug_dir}/tp_repo_debug_${title}",
    }
  }

}
