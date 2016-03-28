# @define tp::dockerize
#
# This define dockerizes an application.
# It can:
#   - Create a dockerfile based on tinydata (default: false)
#   - Build the relevant image (default:false)
#   - Push the image to Docker Hub (default:false)
#   - Run the image from the Docker Hub (default:true)
#
define tp::dockerize (

  String[1]               $ensure              = 'present',

  Variant[Undef,String]   $template            = 'tp/dockerize/Dockerfile.erb',
  Variant[Undef,String]   $init_template       = 'tp/dockerize/init.erb',
  String[1]               $workdir             = '/var/tmp',

  String[1]               $username            = 'example42',

  String[1]               $os                  = downcase($::operatingsystem),
  String[1]               $osversion           = $::operatingsystemmajrelease,

  Variant[Undef,String]   $maintainer          = undef,
  Variant[Undef,String]   $from                = undef,

  Variant[Undef,String]   $repository          = undef,
  Variant[Undef,String]   $repository_tag      = undef,

  Boolean                 $run                 = true,
  Boolean                 $create              = false,
  Boolean                 $build               = false,
  Boolean                 $push                = false,

  String                  $build_options       = '',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',

  ) {

  # Settings evaluation
  $app = $title
  $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  $real_repository = $repository ? {
    undef   => $app,
    default => $repository,
  }
  $real_repository_tag = $repository_tag ? {
    undef   => "${os}-${osversion}",
    default => $repository_tag,
  }
  $real_from = $from ? {
    undef   => "${os}:${osversion}",
    default => $from,
  }
  $real_path = "${workdir}/${os}/${osversion}/${app}/Dockerfile"

  # Dockerfile creation
  if $create {
    if ! defined(File[$workdir]) {
      file { $workdir:
        ensure => directory,
      }
    }
    if ! defined(File["${workdir}/${os}"]) {
      file { "${workdir}/${os}":
        ensure => directory,
      }
    }
    if ! defined(File["${workdir}/${os}/${osversion}"]) {
      file { "${workdir}/${os}/${osversion}":
        ensure => directory,
      }
    }
    if ! defined(File["${workdir}/${os}/${osversion}/${app}"]) {
      file { "${workdir}/${os}/${osversion}/${app}":
        ensure => directory,
      }
    }

    file { "${workdir}/${os}/${osversion}/${app}/Dockerfile":
      ensure  => $ensure,
      content => template($template),
    }
  }

  # Image build
  if $build and $ensure == 'present' {
    exec { "docker build ${build_options} -t ${username}/${real_repository}:${real_repository_tag} .":
      cwd         => "${workdir}/${os}/${osversion}/${app}",
      path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
      subscribe   => File["${workdir}/${os}/${osversion}/${app}/Dockerfile"],
      refreshonly => true,
      timeout     => 0,
    }
  }

  # Image upload to Docker Hub
  if $push and $ensure == 'present' {
    exec { "docker push ${username}/${real_repository}:${real_repository_tag}":
      cwd         => "${workdir}/${os}/${osversion}/${app}",
      path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
      subscribe   => Exec["docker build ${build_options} -t ${username}/${real_repository}:${repository_tag} ."],
      refreshonly => true,
      timeout     => 0,
    }
  }

  # Image run
  if $run {
    $service_ensure = $ensure ? {
      'absent' => 'stopped',
      false    => 'stopped',
      default  => $settings[service_ensure],
    }
    $service_enable = $ensure ? {
      'absent' => false,
      false    => false,
      default  => $settings[service_enable],
    }
    file { "/etc/init/docker-${app}":
      ensure  => $ensure,
      content => template($init_template),
      mode    => '0755',
      notify  => Service["docker-${app}"],
    }
    service { "docker-${app}":
      ensure  => $service_ensure,
      enable  => $service_enable,
    }
  }

}
