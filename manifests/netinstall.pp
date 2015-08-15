#
#
# = Define: tp::netinstall
#
# This define installs application from their upstream source code
#
#
# == Parameters
#
define tp::netinstall (

  $ensure                     = present,

  # $skip
  $download_enable            = true,
  $source_url                 = undef,
  $source_format              = undef,
  $download_command           = 'wget',
  $download_command_args      = '',
  $download_dir               = '/var/tmp',
  $extracted_dir_name         = '',
  $destination_dir            = "/opt/${title}",
  $destination_dir_hash       = { },
  $destination_dir_user       = undef,
  $destination_dir_group      = undef,

  $prerequisite_packages_hash = { },

  $preinstall_execs_hash      = { },
  $preinstall_exec            = undef,
  $preinstall_files_hash      = { },

  $build_execs_hash           = { },
  $build_exec                 = undef,
  $build_files_hash           = { },

  $install_execs_hash         = { },
  $install_exec               = undef,
  $install_files_hash         = { },

  $postinstall_execs_hash     = { },
  $postinstall_exec           = undef,
  $postinstall_files_hash     = { },

  # Default settings for all execs, can be overridden in *_execs_hash
  $exec_timeout              = '3600',
  $exec_path                 = '/bin:/sbin:/usr/bin:/usr/sbin',
  $exec_env                  = [],
  $exec_cwd                  = undef,

  # Override tp/data/$title/ settings
  $settings_hash             = { } ,

  $extra_class               = undef,
  $dependency_class          = undef,
  $monitor_class             = undef,
  $firewall_class            = undef,

  $puppi_enable              = false,

  $test_enable               = false,
  $test_acceptance_template  = undef,

  $data_module               = 'tinydata',

  ) {

  # Parameters validation
  validate_bool($puppi_enable)
  validate_hash($settings_hash)


  # Settings evaluation
  $settings_defaults = {
    preinstall_exec  => $preinstall_exec,
    prebuild_exec    => $build_exec,
    install_exec     => $install_exec,
    postinstall_exec => $postinstall_exec,
  }
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings=merge($tp_settings,$settings_defaults,$settings_hash)

  ### Dependencies
  if $dependency_class { require $dependency_class }
  if $prerequisite_packages_hash {
    create_resources('package',$prerequisite_packages_hash)
  }

  ### 1 download 
  exec { "download_${title}":
    cwd         => $download_dir,
    command     => "${download_command} ${download_command_args} ${source_url}",
    creates     => "${work_dir}/${source_filename}",
    timeout     => $exec_timeout,
    path        => $exec_path,
    environment => $exec_env,
  }

  ### 2 extract
  exec { "Extract_${title}":
    command     => "mkdir -p ${destination_dir} && cd ${destination_dir} && ${real_extract_command} ${work_dir}/${source_filename} ${extract_command_second_arg}",
    creates     => "${destination_dir}/${real_extracted_dir}",
    timeout     => $exec_timeout,
    require     => Exec["download_${title}"],
    path        => $exec_path,
    environment => $exec_env,
    notify      => Exec["Chown_${title}_dirs"],
  }

  ### Chown 
  exec { "Chown_${title}_dirs":
    command     => "chown -R ${destination_dir_user}:${destination_dir_group} ${destination_dir}/${real_extracted_dir}",
    refreshonly => true,
    timeout     => $exec_timeout,
    require     => Exec["Extract_${title}"],
    path        => $exec_path,
    environment => $exec_env,
  }


  ### pre install file and exec
  if $settings['preinstall_files_hash'] {
    $preinstall_files_defaults = {
      "preinstall_${title}" => {
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Exec["preinstall_${title}"],
      }
    }
    # resources_deep_merge is provided by puppetcommunity-extlib
    $preinstall_files = resources_deep_merge($preinstall_files_defaults, $preinstall_files_hash)
    create_resources('file', $preinstall_files)
  }

  if $settings['preinstall_exec'] {
    $preinstall_execs_defaults = {
      "preinstall_${title}" => {
        command     => $settings['preinstall_exec'],
        subscribe   => Exec["download_${title}"],
        refreshonly => true,
        timeout     => $exec_timeout,
        cwd         => $exec_cwd,
        environment => $exec_env,
        path        => $exec_path,
      }
    }
    $preinstall_execs = merge($preinstall_execs_defaults,$preinstall_execs_hash)
    create_resources('exec', $preinstall_execs)
  }


  ### build file and exec
  if $settings['build_files_hash'] {
    $build_files_defaults = {
      "build_${title}" => {
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Exec["build_${title}"],
      }
    }
    # resources_deep_merge is provided by puppetcommunity-extlib
    $build_files = resources_deep_merge($build_files_defaults, $build_files_hash)
    create_resources('file', $build_files)
  }

  if $settings['build_exec'] {
    $build_execs_defaults = {
      "build_${title}" => {
        command     => $settings['build_exec'],
        subscribe   => [Exec["download_${title}"],Exec["preinstall_${title}"]],
        refreshonly => true,
        timeout     => $exec_timeout,
        cwd         => $exec_cwd,
        environment => $exec_env,
        path        => $exec_path,
      }
    }
    $build_execs = merge($build_execs_defaults,$build_execs_hash)
    create_resources('exec', $build_execs)
  }

  ###  install file and exec
  if $settings['install_files_hash'] {
    $install_files_defaults = {
      "install_${title}" => {
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Exec["install_${title}"],
      }
    }
    # resources_deep_merge is provided by puppetcommunity-extlib
    $install_files = resources_deep_merge($install_files_defaults, $install_files_hash)
    create_resources('file', $install_files)
  }

  if $settings['install_exec'] {
    $install_execs_defaults = {
      "install_${title}" => {
        command     => $settings['install_exec'],
        subscribe   => Exec["download_${title}"],
        refreshonly => true,
        timeout     => $exec_timeout,
        cwd         => $exec_cwd,
        environment => $exec_env,
        path        => $exec_path,
      }
    }
    $install_execs = merge($install_execs_defaults,$install_execs_hash)
    create_resources('exec', $install_execs)
  }


  ### post install file and exec
  if $settings['postinstall_files_hash'] {
    $postinstall_files_defaults = {
      "postinstall_${title}" => {
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Exec["postinstall_${title}"],
      }
    }
    # resources_deep_merge is provided by puppetcommunity-extlib
    $postinstall_files = resources_deep_merge($postinstall_files_defaults, $postinstall_files_hash)
    create_resources('file', $postinstall_files)
  }

  if $settings['postinstall_exec'] {
    $postinstall_execs_defaults = {
      "postinstall_${title}" => {
        command     => $settings['postinstall_exec'],
        subscribe   => Exec["install_${title}"],
        refreshonly => true,
        timeout     => $exec_timeout,
        cwd         => $exec_cwd,
        environment => $exec_env,
        path        => $exec_path,
      }
    }
    $postinstall_execs = merge($postinstall_execs_defaults,$postinstall_execs_hash)
    create_resources('exec', $postinstall_execs)
  }


  # Optional puppi integration 
  if $puppi_enable == true {
    tp::puppi { $title:
      settings_hash => $settings,
    }
  }

  # Test script creation (use to test, check, monitor the app)
  if $test_enable == true {
    tp::test { $title:
      settings_hash       => $settings,
      acceptance_template => $test_acceptance_template,
    }
  }

  # Extra classes
  if $extra_class { include $extra_class }
  if $monitor_class { include $monitor_class }
  if $firewall_class { include $firewall_class }

}
