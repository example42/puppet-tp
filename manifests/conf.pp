# @define tp::conf
#
# This define manages configuration files for the the application (app)
# set in the given title.
# It can manage the content of the managed files using different
# methods (source, template, epp, content)
# Th actual path of the managed configuration files is determined by
# various elements:
# - If the path parameter is passed, that's the path used
# - If no path is explicitly set and the title contains only the app
#   name, then it's managed the MAIN configuration of the application,
#   as determined tp's data/ directory.
# - If no path is set and the title has a format like: app::file, then
#   the path is composed using tha app's main configuration directory and
#   the file name used in the title (after the ::)
# See the examples below for more details.
#
# @example management of openssh main configuration file
# (/etc/ssh/sshd_config) using a template
#
#   tp::conf { 'openssh':
#     template => 'site/openssh/sshd_config',
#   }
#
# @example management of openssh client file (/etc/ssh/ssh_config) using
# a static source
#
#   tp::conf { 'openssh::ssh_config':
#     source => 'puppet:///modules/site/openssh/ssh_config',
#   }
#
# @example management of a file related to openssh with an
# explicit path given (In this case the title is not used for
# any specific purpose, but it should have a unique name and
# refer to the relevat app in he first part of the title (before ::) 
#
#   tp::conf { 'openssh::root_config':
#     path   => '/root/.ssh/config',
#     source => 'puppet:///modules/site/openssh/root/config',
#   }
#
#
# @param ensure                    Default: present
#   Define the status of the file: present (default value) or absent
#
# @param path                      Default: undef
#   The actual path of the file to manage. When this is set, it take precedence
#   over any other automatic paths definition.
#
# @param source                    Default: undef,
#   Source of the file to use. Used in the managed file as follows:
#   source => $source,
#   This parameter is alternative to content, template and epp.
#
# @param template                  Default: undef,
#   Erb Template to use for the content of the file. Used as follows:
#   content => template($template),
#   This parameter is alternative to content, source and epp.
#
# @param epp                       Default: undef,
#   Epp Template to use for the content of the file. Used as follows:
#   content => epp($epp),
#   This parameter is alternative to content, source and template.
#
# @param content                   Default: undef,
#   Content of the file. Used as follows:
#   content => $content,
#   This parameter is alternative to source, template and epp.
#
# @param options_hash              Default: { },
#   Generic hash of configuration parameters specific for the app that can be
#   used in the provided erb or epp templates respectively as @options_hash['key'] or
#   $options_hash['key']
#
# @param mode                      Default: undef
#   Parameter mode for the managed file resource.
#   By default is defined according to app and OS, the same applies for the
#   following params.
#
# @param owner                     Default: undef
#   Parameter owner for the managed file resource.
#
# @param group                     Default: undef
#   Parameter group for the managed file resource.
#
# @param config_file_notify        Default: true
#   By default changes in the managed file trigger a service restart of the
#   app in the title. Set to false to avoid any restart of set the name of a Puppet
#   resource to notify. (Ex: Service[nginx])
#
# @param config_file_require       Default: true,
#   By default the file managed requires the app package, if tp::install has
#   not been used to install the app, you may have references to an unknown
#   resource. Set this to false to not set any dependency, or define a resource
#   to require before managing the file (Ex: Package[apache2])
#
# @param debug                     Default: false,
#   If set to true it prints debug information for tp into the directory set in
#   debug_dir
#
# @param debug_dir                 Default: '/tmp',
#   The directory where tp stoes dbug info, when enabled
#
# @param data_module               Default: 'tp'
#   Name of the module where tp data is looked for
#
#
define tp::conf (

  $ensure               = present,

  $source               = undef,
  $template             = undef,
  $epp                  = undef,
  $content              = undef,

  $base_dir             = 'config',

  $path                 = undef,
  $mode                 = undef,
  $owner                = undef,
  $group                = undef,

  $config_file_notify   = true,
  $config_file_require  = true,

  $options_hash         = undef,

  $debug                = false,
  $debug_dir            = '/tmp',

  $data_module          = 'tp',

  ) {

  # Parameters validation
  validate_bool($debug)
  validate_re($ensure, ['present','absent'], 'Valid values are: present, absent. WARNING: If set to absent the conf file is removed.')


  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $file = $title_elements[1]
  $settings = tp_lookup($app,'settings',$data_module,'merge')

  if $file {
    # TODO: Find a way to interpolate $base_dir 
    $auto_path = $base_dir ? {
      'config' => "${settings[config_dir_path]}/${file}",
      'conf'   => "${settings[conf_dir_path]}/${file}",
      'data'   => "${settings[data_dir_path]}/${file}",
      'log'    => "${settings[log_dir_path]}/${file}",
      'ssl'    => "${settings[ssl_dir_path]}/${file}",
      default  => "${settings[config_dir_path]}/${file}",
    }
  } else {
    $auto_path = $settings['config_file_path']
  }
  $manage_path    = tp_pick($path, $auto_path)
  $manage_content = tp_content($content, $template, $epp)
  $manage_mode    = tp_pick($mode, $settings[config_file_mode])
  $manage_owner   = tp_pick($owner, $settings[config_file_owner])
  $manage_group   = tp_pick($group, $settings[config_file_group])

  # Set require if package_name is present 
  if $settings[package_name] and $settings[package_name] != '' {
    $package_ref = "Package[${settings[package_name]}]"
  } else {
    $package_ref = undef
  }
  $manage_require = $config_file_require ? {
    ''        => undef,
    false     => undef,
    true      => $package_ref,
    default   => $config_file_require,
  }

  # Set notify if service_name is present 
  if $settings[service_name] and $settings[service_name] != '' {
    $service_ref = "Service[${settings[service_name]}]"
  } else {
    $service_ref = undef
  }
  $manage_notify  = $config_file_notify ? {
    ''        => undef,
    false     => undef,
    true      => $service_ref,
    default   => $config_file_notify,
  }


  # Resources
  file { $manage_path:
    ensure  => $ensure,
    source  => $source,
    content => $manage_content,
    path    => $manage_path,
    mode    => $manage_mode,
    owner   => $manage_owner,
    group   => $manage_group,
    require => $manage_require,
    notify  => $manage_notify,
  }


  # Debugging
  if $debug == true {
    $debug_file_params = "
    file { 'tp_conf_${manage_path}':
      ensure  => ${ensure},
      source  => ${source},
      content => ${manage_content},
      path    => ${manage_path},
      mode    => ${manage_mode},
      owner   => ${manage_owner},
      group   => ${manage_group},
      require => ${manage_require},
      notify  => ${manage_notify},
    }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_conf_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_conf_debug_${title}",
    }
  }

}
