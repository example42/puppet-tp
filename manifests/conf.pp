# @define tp::conf
#
# This define manages configuration files for the application named
# in the used title..
# It can manage the content of the managed files using different
# methods (source, template, epp, content)
# The actual path of the managed configuration files is determined by
# various elements:
# - If the path parameter is explicitly set, that's always the path used
#
#   tp::conf { 'openssh::root_config':
#     path                => '/root/.ssh/config', # This is the path of the managed file
#     content             => template('site/openssh/root_config.erb'),
#   }
#
# - If path parameter is not set and the title contains only the app
#   name, which is the basic and most direct usage, then it's managed the
#   *main configuration file* of the application, as defined by the variable
#   config_file_path in the tp/data/$app directory according to the underlying OS.
#
#   tp::conf { 'openssh':  # Path is defined by tp $settings['config_file_path']
#     template            => 'site/openssh/sshd_config.erb',
#   }
#
# - When the base_file parameter is specified the path of the managed file is #
#   looked in the value of the key ${base_file}_file_path in the tp/data/$app directory
#   tp::conf { 'openssh':  # Path is defined by tp $settings['init_file_path']
#     template            => 'site/openssh/init.erb',
#     base_file           => 'init',
#   }
#
# - When the title has a format like: app::file and no base_dir is set the path
#   is composed using the app's *main configuration directory* and the file name
#   used in the second part of the title (after the ::)
#
#   tp::conf { 'openssh::ssh_config': # Path is $settings['config_dir_path']/ssh_config
#     template            => 'site/openssh/ssh_config.erb',
#   }
#
# - When the title has a format like: app::file it's also possible to specify,
#   with the base_dir parameter, the directory where to place the file:
#
#   tp::conf { 'apache::example42.com.conf':
#     template            => 'site/apache/example42.com.conf.erb',
#     base_dir            => 'conf',
#   }
#   Path is: $settings['conf_dir_path']/example42.com.conf
#
# See below for more examples.
#
# @example management of openssh main configuration file
# (/etc/ssh/sshd_config) using a template
#
#   tp::conf { 'openssh':
#     template            => 'site/openssh/sshd_config',
#     options_hash        => lookup('openssh::options_hash'),
#   }
#
#
# @example management of openssh client file (/etc/ssh/ssh_config) using
# a static source
#
#   tp::conf { 'openssh::ssh_config':
#     source              => 'puppet:///modules/site/openssh/ssh_config',
#   }
#
# @example direct management of the content of a file
#
#   tp::conf { 'motd':
#     content             => "Welcome to ${::fqdn}\n",
#   }
#
# @example management of a .conf file (configuration files placed typically
# in directory called conf.d or *.d ). Note that here is used as $base_dir
# 'conf' instead of the default 'config'.
# For example with Apache on RedHat:
# 'config' dir is '/etc/httpd'
# 'conf' dir is '/etc/httpd/conf.d'
# Other "common" base_dir values are 'log', 'data' but actually any value
# can be used as long as there's a corresponding key in the TP settings data.
#
#   tp::conf { 'rsyslog::logserver':
#     content             => "*.* @@syslog.example42.com\n",
#     base_dir            => 'conf',
#   }
#
# @example management of a file related to openssh with an
# explicit path given and the content populated via a Puppet epp template.
# In this case the title is not used for any specific purpose, but it should
# have a unique name and refer to the relevat app in the first part of the title (before ::)
#
#   tp::conf { 'openssh::root_config': # Title must be unique
#     path                => '/root/.ssh/config',
#     epp                 => 'site/openssh/root/config.epp',
#     mode                => '0640',
#   }
#
# @example when no automatic service restart is triggered by configuration file
# changes
#
#   tp::conf { 'nginx':
#     config_file_notify  => false,
#   }
#
# @example to customise notify and require dependencies
#
#   tp::conf { 'nginx::nginx_fe.conf':
#     config_file_notify  => 'Service[fe_nginx]',
#     config_file_require => 'Class[site::fe::nginx]',
#   }
#
# @example to disable validation for a configuration file
# By default, if relevant tinydata is present, config files are
# checked. Use this to disable unwanted validation commands
#
#   tp::conf { 'apache::my_vhost.conf':
#     validate_syntax => false,
#     base_dir        => 'vhost,
#     source          => puppet:///modules/profile/apache/my_vhost.conf',
#   }
#
# @example to validate a configuration with a custom command
#
#   tp::conf { 'apache::my_vhost':
#     settings            => {
#       validate_cmd      => '/usr/local/bin/check_apache_vhost',
#     },
#   }
#
# @param ensure Defines the status of the file: present or absent.
#
# @param path The actual path of the file to manage. When this is set, it takes
#   precedence over any other automatic paths definition.
#
# @param source Source of the file to use. Used in the managed file as follows:
#   source                => $source,
#   This parameter is alternative to content, template and epp.
#
# @param template Template (epp or erb) to use for the content of the file. Used as follows:
#   If template value has a suffix .epp:
#   content => epp($template),
#   in all the other not undef cases, used as follows:
#   content => template($template),
#   This parameter is alternative to content, source and epp.
#
# @param epp Epp Template to use for the content of the file. Used as follows:
#   content => epp($epp),
#   This parameter is alternative to content, source and template.
#
# @param content Content of the file. Used as follows:
#   content => $content,
#   This parameter is alternative to source, and has priority over template and epp.
#
# @param base_dir Type of the directory where to place the file, when a path is
#   not explicitly set. This name must have a corresponding entry
#   in TP data with a key named ${base_dir}_dir_path.
#   The default 'config' value maps to the key config_dir_path
#   Common names are:
#     'config' (default) - The app main configuration dir path
#     'conf' - The app conf.d dir where config files can be added
#     'log' - The app logs' directory
#   Each app may have additional names accoring to eventual specific settings.
#
# @param base_file Type of the file managed, when a path is
#   not explicitly set. This name must have a corresponding entry
#   in TP data with a key named ${base_file}_file_path.
#   The default 'config' value maps to the key config_file_path
#   Common names are:
#     'config' (default) - The app main configuration file path
#     'init' - The path of the script that configures init, for that app
#     'log' - The path of the app's log (can be an array)
#     'pid' - The path of the app's pid file
#   Each app may have additional names accoring to eventual specific settings.
#
# @param validate_syntax If to validate the syntax of the file before applying
#   it. By default this is done if there's the relevant $settings[validate_cmd]
#   tinydata. Set to false if you have errors in validation of a (good) provided
#   configuration file.
#
# @param options_hash Generic hash of configuration parameters specific for the
#   app that can be used in the provided erb or epp templates respectively as
#   @options_hash['key'] or $options_hash['key'],
#
# @param my_settings An hash that can override the application settings tp
#   returns, according to the underlying Operating System and the default
#   behaviour.
#
# @param mode Parameter mode for the managed file resource.
#   By default is defined according to app and OS, the same applies for the
#   following params.
#
# @param owner Parameter owner for the managed file resource.
#   The default value for the underlying OS is automatically found by tp.
#
# @param group Parameter group for the managed file resource.
#   The default value for the underlying OS is automatically found by tp.
#
# @param config_file_notify By default changes in the managed file trigger
#   a service restart of the app in the title. Set to false to avoid any
#   restart of set the name of a Puppet resource to notify. (Ex: Service[nginx]).
#
# @param config_file_require By default the file managed requires the app
#   package, if tp::install has not been used to install the app, you may
#   have references to an unknown resource.
#   Set this to false to not set any dependency, or define a resource
#   to require before managing the file (Ex: Package[apache2]).
#
# @param debug If set to true it prints debug information for tp into the
#   directory set in debug_dir
#
# @param debug_dir The directory where tp stores debug info, if enabled.
#
# @param data_module Name of the module where tp data is looked for
#  Default is tinydata: https://github.com/example42/tinydata
#
define tp::conf (

  String[1]               $ensure              = present,

  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),
  Hash                       $my_settings      = {},
  Hash                       $my_options       = {},
  Boolean                    $use_v4           = pick(getvar('tp::use_v4'),false),

  Variant[Undef,String,Array] $source          = undef,
  Variant[Undef,String,Array] $template        = undef,
  Variant[Undef,String]   $epp                 = undef,
  Variant[Undef,String]   $content             = undef,

  String[1]               $base_dir            = 'config',
  String[1]               $base_file           = 'config',

  Enum['global','user']   $scope               = 'global',

  Variant[Undef,String]   $path                = undef,
  Variant[Undef,String]   $mode                = undef,
  Variant[Undef,String]   $owner               = undef,
  Variant[Undef,String]   $group               = undef,

  String                  $path_prefix         = '',    # lint:ignore:params_empty_string_assignment
  Boolean                 $path_parent_create  = false,

  Variant[Boolean,String] $config_file_notify  = true,
  Variant[Boolean,String] $config_file_require = true,

  Variant[Undef,Boolean]  $validate_syntax     = undef,

  Hash                    $options_hash        = {},
  Hash                    $settings_hash       = {},

  Boolean                 $debug               = false,
  String[1]               $debug_dir           = '/tmp',

  String[1]               $data_module         = 'tinydata',

) {
  # Deprecations
  if $settings_hash != {} {
    tp::fail($on_missing_data, "Module ${caller_module_name} needs updates: Parameter settings_hash in tp::conf is deprecated, replace it with my_settings")
  }
  if $options_hash != {} {
    tp::fail($on_missing_data, "Module ${caller_module_name} needs updates: Parameter options_hash in tp::conf is deprecated, replace it with my_options")
  }

  if $use_v4 {
    # Settings evaluation
    $title_elements = split ($title, '::')
    $app = $title_elements[0]
    $file = $title_elements[1]

    # Check if repo or upstream_repo are set in tp::install
    if defined_with_params(Tp::Install[$app]) {
      $repo = getparam(Tp::Install[$app],'repo')
    }
    if defined_with_params(Tp::Install[$app]) {
      $upstream_repo = getparam(Tp::Install[$app],'upstream_repo')
    }

    $tp_settings = tp_lookup($app,'settings',$data_module,'deep_merge')
    $temp_settings = deep_merge($tp_settings,$settings_hash,$my_settings)

    # Find file path
    $prefix = $scope ? {
      'global' => $facts['identity']['privileged'] ? {
        true  => '',
        false => 'user_',
      },
      'user'   => 'user_',
    }
    if $file and $file != '' {
      $real_dir = pick(getvar("temp_settings.${base_dir}_dir_path"), getvar("temp_settings.${prefix}dirs.${base_dir}.path"))
      $auto_path = $base_file ? {
        'config' => "${real_dir}/${file}",
        default  => pick(getvar("temp_settings.${base_file}_file_path"), getvar("temp_settings.${prefix}files.${base_file}.path"))
      }
    } else {
      $auto_path = pick(getvar("temp_settings.${base_file}_file_path"), getvar("temp_settings.${prefix}files.${base_file}.path"))
    }
    $calculated_path  = pick($path, $auto_path)
    $real_path    = "${path_prefix}${calculated_path}"

    $local_file_params = delete_undef_values({
        'path'    => $real_path,
        'mode'    => $mode,
        'owner'   => $owner,
        'group'   => $group,
    })

    $local_settings = delete_undef_values({
        "${prefix}files" => {
          "${base_file}" => $local_file_params,
        },
        "${base_file}_file_mode" => $mode,
        "${base_file}_file_owner" => $owner,
        "${base_file}_file_group" => $group,
        "${base_file}_file_path" => $real_path,
    })
    $settings = deep_merge($tp_settings,$settings_hash,$my_settings,$local_settings)

    $real_mode  = pick(getvar("settings.${base_file}_file_mode"), getvar("settings.${prefix}files.${base_file}.mode"), getvar('settings.config_file_mode')) # lint:ignore:140chars
    $real_owner = pick(getvar("settings.${base_file}_file_owner"), getvar("settings.${prefix}files.${base_file}.owner"), getvar('settings.config_file_owner')) # lint:ignore:140chars
    $real_group = pick(getvar("settings.${base_file}_file_group"), getvar("settings.${prefix}files.${base_file}.group"), getvar('settings.config_file_group')) # lint:ignore:140chars

    # Set options and file content
    $tp_options = tp_lookup($app,"options::${base_file}",$data_module,'deep_merge')
    $options = deep_merge($tp_options,$options_hash,$my_options,)

    $epp_params = {
      options      => $options,
      options_hash => $options_hash,
      settings     => $settings,
    }
    if $content {
      $content_params = $content
    } elsif $template {
      $template_ext = $template[-4,4]
      $content_params = $template_ext ? {
        '.epp'  => epp($template,$epp_params),
        '.erb'  => template($template),
        default => template($template),
      }
    } elsif $epp {
      $content_params = epp($epp,$epp_params)
    } else {
      $content_params = undef
    }

    # If user doesn't provide a $content, $template or $epp but provides $options_hash we check
    # if on tinydata is set config_file_format
    $real_config_file_format = pick_default(getvar("settings.${base_file}_file_format"), getvar("settings.${prefix}files.${base_file}.file_format"), getvar("settings.files.${base_file}.file_format"),undef)
    if $content_params =~ Undef and $real_config_file_format and $options != {} {
      $real_content = $real_config_file_format ? {
        'yaml' => to_yaml($options),
        'json' => to_json($options),
        'hcl' => to_hcl($options),
        'inifile' => template('tp/inifile.erb'),
        'inifile_with_stanzas' => template('tp/inifile_with_stanzas.erb'),
        'spaced' => template('tp/spaced.erb'),
        'spaced_with_stanzas' => template('tp/inifile_with_stanzas.erb'),
        default => undef,
      }
    } else {
      $real_content = $content_params
    }

    # Set require if package_name is present
    $real_package_name = pick_default(getvar('settings.package_name'), tp::title_replace(getvar('settings.packages.main.name'),$app),undef)
    if $real_package_name and $real_package_name != '' {
      $package_ref = "Package[${real_package_name}]"
    } else {
      $package_ref = undef
    }
    $real_require = $config_file_require ? {
      ''        => undef,
      false     => undef,
      true      => $package_ref,
      default   => $config_file_require,
    }

    # Set notify if service_name is present
    $real_service_name = pick_default(getvar('settings.service_name'), tp::title_replace(getvar('settings.services.main.name'),$app),undef)
    if $real_service_name and $real_service_name != '' {
      $service_ref = "Service[${real_service_name}]"
    } else {
      $service_ref = undef
    }
    $real_notify  = $config_file_notify ? {
      ''        => undef,
      false     => undef,
      true      => $service_ref,
      default   => $config_file_notify,
    }
    $validate_cmd = pick_default(getvar('settings.validate_cmd'), getvar("settings.${prefix}files.${base_file}.validate_cmd"), undef) # lint:ignore:140chars
    $default_validate_cmd = $validate_cmd ? {
      ''     => undef,
      String => $validate_cmd,
      Hash   => getvar("settings.validate_cmd.${base_dir}"),
      Undef  => undef,
    }
    $real_validate_cmd = $validate_syntax ? {
      undef => $default_validate_cmd,
      true  => $default_validate_cmd,
      false => undef,
    }
    # Resources
    if $path_parent_create {
      $path_parent = dirname($real_path)
      exec { "mkdir for tp::conf ${title}":
        command => "/bin/mkdir -p ${path_parent}",
        creates => $path_parent,
        before  => File[$real_path],
      }
    }
    $file_params = {
      ensure       => tp::ensure2file($ensure),
      source       => $source,
      content      => $real_content,
      path         => $real_path,
      mode         => $real_mode,
      owner        => $real_owner,
      group        => $real_group,
      require      => $real_require,
      notify       => $real_notify,
      validate_cmd => $real_validate_cmd,
    }

    file { $real_path:
      * => $file_params + pick(getvar("settings.${base_file}_file_params"), getvar("settings.${prefix}files.${base_file}.params"), getvar("settings.files.${base_file}.params"), {}),
    }
  } else {
    #v3 code

    # Settings evaluation
    $title_elements = split ($title, '::')
    $app = $title_elements[0]
    $file = $title_elements[1]

    if defined_with_params(Tp::Install[$app]) {
      $repo = getparam(Tp::Install[$app],'repo')
    }
    if defined_with_params(Tp::Install[$app]) {
      $upstream_repo = getparam(Tp::Install[$app],'upstream_repo')
    }
    $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
    $settings = deep_merge($tp_settings,$settings_hash,$my_settings)

    $tp_options = tp_lookup($app,"options::${base_file}",$data_module,'merge')
    $options = deep_merge($tp_options,$options_hash,$my_options,)

    if $file and $file != '' {
      $prefix = $scope ? {
        'global' => '',
        'user'   => 'user_',
      }
      $real_dir = $settings["${prefix}${base_dir}_dir_path"]
      $auto_path = $base_file ? {
        'config' => "${real_dir}/${file}",
        default  => $settings["${prefix}${base_file}_file_path"],
      }
    } else {
      $auto_path = $settings["${base_file}_file_path"]
    }
    $real_path      = pick($path, $auto_path)
    $manage_path    = "${path_prefix}${real_path}"
    $manage_mode    = pick($mode, $settings[config_file_mode])
    $manage_owner   = pick($owner, $settings[config_file_owner])
    $manage_group   = pick($group, $settings[config_file_group])

    $epp_params = {
      options      => $options,
      options_hash => $options_hash,
      settings     => $settings,
    }
    # Find out the file's content value
    if $content {
      $content_params = $content
    } elsif $template {
      $template_ext = $template[-4,4]
      $content_params = $template_ext ? {
        '.epp'  => epp($template,$epp_params),
        '.erb'  => template($template),
        default => template($template),
      }
    } elsif $epp {
      $content_params = epp($epp,$epp_params)
    } else {
      $content_params = undef
    }

    # If user doesn't provide a $content, $template or $epp but provides $options_hash we check
    # if on tinydata is set config_file_format
    if $content_params =~ Undef and $settings[config_file_format] and $options != {} {
      $manage_content = $settings[config_file_format] ? {
        'yaml' => to_yaml($options_hash),
        'json' => to_json($options_hash),
        'hcl' => to_hcl($options_hash),
        'inifile' => template('tp/inifile.erb'),
        'inifile_with_stanzas' => template('tp/inifile_with_stanzas.erb'),
        'spaced' => template('tp/spaced.erb'),
        'spaced_with_stanzas' => template('tp/inifile_with_stanzas.erb'),
        default => undef,
      }
    } else {
      $manage_content = $content_params
    }

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

    $default_validate_cmd = $settings['validate_cmd'] ? {
      ''     => undef,
      String => $settings['validate_cmd'],
      Hash   => $settings['validate_cmd'][$base_dir],
      Undef  => undef,
    }
    $manage_validate_cmd = $validate_syntax ? {
      undef => $default_validate_cmd,
      true  => $default_validate_cmd,
      false => undef,
    }

    # Resources
    if $path_parent_create {
      $path_parent = dirname($manage_path)
      exec { "mkdir for tp::conf ${title}":
        command => "/bin/mkdir -p ${path_parent}",
        creates => $path_parent,
        before  => File[$manage_path],
      }
    }
    $file_params = {
      ensure       => $ensure,
      source       => $source,
      content      => $manage_content,
      path         => $manage_path,
      mode         => $manage_mode,
      owner        => $manage_owner,
      group        => $manage_group,
      require      => $manage_require,
      notify       => $manage_notify,
      validate_cmd => $manage_validate_cmd,
    }

    file { $manage_path:
      * => $file_params + pick($settings[config_file_params], {}),
    }

    # Debugging
    if $debug == true {
      $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
      file { "tp_conf_debug_${title}":
        ensure  => $ensure,
        content => $debug_scope,
        path    => "${debug_dir}/tp_conf_debug_${title}",
      }
    }
  }
}
