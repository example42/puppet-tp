#
# Define tp::repo
#
# Manages a yum/apt repo for an application
#
define tp::repo (

  Boolean                   $enabled             = true,

  String[1]                 $description         = "${title} repository",

  Variant[Undef,String[1]]  $repo_url            = undef,
  Variant[Undef,String[1]]  $key_url             = undef,
  Variant[Undef,String[1]]  $key                 = undef,

  Variant[Undef,Integer]    $yum_priority        = undef,
  Variant[Undef,String[1],Boolean] $yum_gpgcheck        = undef,
  Variant[Undef,String[1]] $yum_mirrorlist      = undef,

  Variant[Undef,String[1]] $apt_key_server      = undef,
  Variant[Undef,String[1]] $apt_key_fingerprint = undef,
  Variant[Undef,String[1]] $apt_release         = undef,
  Variant[Undef,String[1]] $apt_repos           = undef,
  Variant[Undef,String[1]] $apt_pin             = undef,
  Boolean                  $apt_include_src     = false,

  Boolean                  $debug               = false,
  String[1]                $debug_dir           = '/tmp',

  String[1]                $data_module         = 'tinydata',

) {

  # Parameters validation
  validate_bool($enabled)
  validate_bool($debug)


  # Settings evaluation
  $enabled_num = bool2num($enabled)
  $ensure      = bool2ensure($enabled)
  $tp_settings = tp_lookup($title,'settings',$data_module,'merge')
  $user_settings = {
    repo_url            => $repo_url,
    key_url             => $key_url,
    key                 => $key,
    apt_key_server      => $apt_key_server,
    apt_key_fingerprint => $apt_key_fingerprint,
    apt_release         => $apt_release,
    yum_priority        => $yum_priority,
    yum_mirrorlist      => $yum_mirrorlist,
    apt_repos           => $apt_repos,
    apt_release         => $apt_release,
    apt_include_src     => $apt_include_src,
    apt_pin             => $apt_pin,
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
    'RedHat': {
      if !defined(Yumrepo[$title]) {
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
      and is_string($settings[package_name])
      and $settings[package_name] != ''
      and $settings[package_name] != undef
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


  # Debugging
  if $debug == true {

    $debug_file_params = "
      yumrepo { ${title}:
        enabled        => ${enabled_num},
        descr          => ${description},
        baseurl        => ${settings[repo_url]},
        gpgcheck       => ${manage_yum_gpgcheck},
        gpgkey         => ${settings[key_url]},
        priority       => ${settings[yum_priority]},
      }

      apt::source { ${title}:
        ensure     => ${ensure},
        comment    => ${description},
        location   => ${settings[repo_url]},
        key        => ${settings[key]},
        key_source => ${settings[key_url]},
        key_server => ${settings[apt_key_server]},
        repos      => ${settings[apt_repos]},
        release    => ${settings[apt_release]},
        pin        => ${settings[apt_pin]},
      }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_repo_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_repo_debug_${title}",
    }
  }

}
