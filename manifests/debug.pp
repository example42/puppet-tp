# tp::debug
#
# Creates debug scripts to check if the application managed
# by Tiny Puppet is runnign correctly.
#
define tp::debug (

  Variant[Boolean,String] $ensure              = present,
  Variant[Undef,String]   $path                = undef,
  Variant[Undef,String,Array] $source          = undef,
  Variant[Undef,String,Array] $template        = undef,
  Variant[Undef,String]   $epp                 = undef,
  Variant[Undef,String]   $content             = undef,

  Hash                    $my_options          = {},
  Hash                    $options_hash        = {},

  Hash                    $my_settings         = {},
  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',
  String[1]               $base_dir            = '/etc/tp/debug',
  String[1]               $app_dir             = '/etc/tp/app',

  Stdlib::Absolutepath    $debug_command       = $tp::debug_script_path,
  Boolean                 $verbose             = false,
  Boolean                 $cli_enable          = pick($tp::cli_enable, true),

) {
  # Deprecations
  if $settings_hash != {} {
    tp::fail('notify', "Module ${caller_module_name} needs updates: Parameter settings_hash in tp::debug is deprecated, replace it with my_settings")
  }
  if $options_hash != {} {
    tp::fail('notify', "Module ${caller_module_name} needs updates: Parameter options_hash in tp::debug is deprecated, replace it with my_options")
  }

  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'deep_merge')
  $settings = deep_merge($tp_settings,$settings_hash,$my_settings)

  include tp

  # Default options and computed variables
  $options_defaults = {
    debug_command           => $debug_command,
  }

  $options = deep_merge($options_defaults, $options_hash, $my_options)

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

  $real_path = $path ? {
    undef   => "${base_dir}/${sane_title}",
    default => $path,
  }
  if $file_content
  or $source {
    file { $real_path:
      ensure  => $ensure,
      mode    => '0755',
      owner   => 'root',
      content => $file_content,
      source  => $source,
      tag     => 'tp_debug',
    }
  }
}
