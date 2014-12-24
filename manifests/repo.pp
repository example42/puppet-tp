#
# Define tp::repo
#
# Manages a yum/apt repo for an application
#
define tp::repo (

  $enabled       = true,

  $description   = "${title} repository",

  $repo_url       = undef,
  $key_url        = undef,
  $key            = undef,

  $yum_priority   = undef,
  $yum_gpgcheck   = undef,

  $apt_key_server = undef,
  $apt_release    = undef,
  $apt_repos      = undef,
  $apt_pin        = undef,

  $debug          = false,
  $debug_dir      = '/tmp',

  $data_module    = 'tp',

) {

  # Parameters validation
  validate_bool($enabled)
  validate_bool($debug)


  # Settings evaluation
  $enabled_num = bool2num($enabled)
  $ensure      = bool2ensure($enabled)
  $tp_settings = tp_lookup($title,'settings',$data_module,'merge')
  $user_settings = {
    repo_url       => $repo_url,
    key_url        => $key_url,
    key            => $key,
    apt_key_server => $apt_key_server,
    apt_release    => $apt_release,
    yum_priority   => $yum_priority,
    apt_repos      => $apt_repos,
    apt_pin        => $apt_pin,
  }
  $user_settings_clean = delete_undef_values($user_settings)
  $settings = merge($tp_settings,$user_settings_clean)

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
      yumrepo { $title:
        enabled        => $enabled_num,
        descr          => $description,
        baseurl        => $settings[repo_url],
        gpgcheck       => $manage_yum_gpgcheck,
        gpgkey         => $settings[key_url],
        priority       => $settings[yum_priority],
      }
    }
    'Debian': {
      apt::source { $title:
        ensure     => $ensure,
        comment    => $description,
        location   => $settings[repo_url],
        key        => $settings[key],
        key_source => $settings[key_url],
        key_server => $settings[apt_key_server],
        repos      => $settings[apt_repos],
        pin        => $settings[apt_pin],
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

      apt::source { $title:
        ensure     => ${ensure},
        comment    => ${description},
        location   => ${settings[repo_url]},
        key        => ${settings[key]},
        key_source => ${settings[key_url]},
        key_server => ${settings[apt_key_server]},
        repos      => ${settings[apt_repos]},
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
