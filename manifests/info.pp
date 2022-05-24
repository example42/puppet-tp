# tp::info
#
# Creates info scripts to check if the application managed
# by Tiny Puppet is runnign correctly.
#
define tp::info (

  Variant[Boolean,String] $ensure              = present,

  Variant[Undef,String,Array] $source          = undef,
  Variant[Undef,String,Array] $template        = undef,
  Variant[Undef,String]   $epp                 = undef,
  Variant[Undef,String]   $content             = undef,

  Hash                    $options_hash        = {},
  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',
  String[1]               $base_dir            = '/etc/tp/info',
  String[1]               $app_dir             = '/etc/tp/app',

  Stdlib::Absolutepath    $info_command        = $tp::info_script_path,
  Boolean                 $verbose             = false,
  Boolean                 $cli_enable          = false,

) {
  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  include tp

  # Default options and computed variables
  $options_defaults = {
    info_command           => $info_command,
  }

  $options = merge($options_defaults, $options_hash)

  $array_package_name=any2array($settings['package_name'])
  $array_service_name=any2array($settings['service_name'])
  $array_tcp_port=any2array($settings['tcp_port'])

  $epp_params = {
    options => $options,
    options_hash => $options_hash,
  }
  # Find out the file's content value
  if $content {
    $file_content = $content
  } elsif $template {
    $template_ext = $template[-4,4]
    $file_content = $template_ext ? {
      '.epp'  => epp($template,$epp_params),
      '.erb'  => template($template),
      default => template($template),
    }
  } elsif $epp {
    $file_content = epp($epp,$epp_params)
  } else {
    $file_content = undef
  }

  $sane_title = regsubst($title, '/', '_', 'G')

  if $file_content
  or $source {
    file { "${base_dir}/${sane_title}":
      ensure  => $ensure,
      mode    => '0755',
      owner   => 'root',
      content => $file_content,
      source  => $source,
      tag     => 'tp_info',
    }
  }

}
