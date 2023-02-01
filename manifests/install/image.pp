# @define tp::install::image
#
# This define installs the application (app) set in the given title git as a
# docker image. Is $manage_service is set to true, it will also manage the
# relevant service.
#
# This define is declared from the tp::install define when $install_method is set
# to 'image' either via a params entry or directly in tinydata settings.
#
# @param ensure If to install (present), remove (absent), ensure is at a
#   specific version.
#
# @param on_missing_data What to do if tinydata is missing.
#
# @param tp_params The tp_params hash to use. If not set, the global $tp::tp_params
#   is used.
#
# @param settings Custom settings hash. It's merged with and can
#   override the default tinydata settings key for the managed app
#
# @param auto_prereq If to automatically install the app's prerequisites
#   (if defined in tinydata)
#
# @param version The version to install. If not set, what's set in the ensure
#   parameter is used
#
# @param docker_image The container image to use. If not explictly set, it's
#   derived from the app's tinidata settings image.name (v4) or docker_image (v3)
#
# @param owner The owner of the app's downloaded and extracted files
#
# @param group The group of the app's downloaded and extracted files
#
# @param manage_service If to manage the app's service
#
# @param data_module The module where to find the tinydata for the app
#
# @example Install an app as a docker image. (Tinydaya must be present)
#   tp::install { 'prometheus':
#     install_method => 'image',
#   }
#
define tp::install::image (
  Variant[Boolean,String] $ensure = present,

  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

  Hash $tp_params                 = pick($tp::tp_params, {}),
  Hash $settings                  = {},

  Boolean $auto_prereq            = pick($tp::auto_prereq, false),

  Optional[String] $version       = undef,
  Optional[String] $docker_image  = undef,
  String[1] $owner                = pick(getvar('identity.user'),'root'),
  String[1] $group                = pick(getvar('identity.group'),'root'),

  Boolean $manage_service         = true,

  String[1] $data_module          = 'tinydata',
) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')

  $real_docker_image = $ensure ? {
    'absent' => false,
    default  => pick($docker_image, getvar('settings.image.name'), getvar('settings.docker_image'), false),
  }

  if $real_docker_image != false {
    if $manage_service {
      tp::service { $app:
        ensure          => $ensure,
        on_missing_data => $on_missing_data,
        settings        => $settings,
        mode            => 'docker',
        docker_image    => $real_docker_image,
        my_options      => getvar('settings.image.systemd_options', {}),
      }
    } else {
      exec { "tp::install::image::${app}::docker::pull":
        command => "docker pull ${real_docker_image}",
        path    => $facts['path'],
        unless  => "docker images | grep -q ${real_docker_image}",
      }
    }
  } else {
    tp::fail($on_missing_data, "tp::install::image ${app} - Missing parameter docker_image or tinydata: settings.image.name or settings.docker_image") # lint:ignore:140chars
  }
}
