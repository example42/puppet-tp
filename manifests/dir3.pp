# @define tp::dir3
#
# Note: This is a Puppet 3.x compatible version of tp::dir
#
# This define manages whole directories related to the application (app)
# set in the title.
# If the vcsrepo parameter is set, the content of the directory is populated
# from the url defined in the source parameter.
# If no vcsrepo is used, the directory is manage by the native file resource.
# The actual path of the managed directory is determined with this logic:
# - If the path parameter is passed, that's the path used
# - If an absolute dir path is set in the title, then it's used this path
# - If no path is explicitly set and the title contains only the app
#   name (ex: 'apache') then it's managed its *main* configuration directory
#   as determined tp's data/ directory.
# - If no path is set and the title is :: separated (ex: 'apache::conf'), then
#   the dir path name is set by the second element set in the title.
#   Currently supported values for dir types are:
#    - config (default, it refers to the main configuraion directory of the app)
#    - conf (a conf.d style directory where to place configuration fragments)
#    - log (the logs dir, if exists)
#    - data (where application data is stored)
#   Planned, and TODO, support for any name for directory types
#
# @example management of apache main configuration directory:
#
#   tp::dir3 { 'apache':
#     source => 'puppet:///modules/site/apache/role/fe',
#   }
#
# @example management of apache logs directory:
#
#   tp::dir3 { 'apache::logs': # The logs name here is needed just to have an unique title
#     base_dir => 'log',
#     mode     => '0640',
#   }
#
# @example management of the directory set as title, with the purge enforcement
# that removes any local file not present on the source directory (Be careful
# with purge ad force params, they can delete files)
#
#   tp::dir3 { '/data/www/default':
#     source => 'puppet:///modules/site/apache/role/fe',
#     purge  => true,
#     force  => true,
#   }
#
#
# @param ensure                    Default: present
#   Define the status of the directory: present (default value) or absent
#
# @param source                    Default: undef
#   This sets the source content for the managed dir.
#   When the vcsrepo option is set it accepts any vcs tool's supported url.
#   For example: https://github.com/example42/puppet-tp 
#   By default a normal directory is managed, whose content may be
#   populated referring to a directory like: puppet:///modules/site/app/test/
#   This would refer to the content of the directory $MODULEPATH/site/files/app/test/ 
#
# @param vcsrepo                   Default: undef
#   If set the directory is managed via the vcsrepo resource.
#   vcsrepo options are bzr, cvs, git, hg, p4, svn
#   It requires a valid source parameter
#
# @param base_dir                  Default: 'config',
#   Type of the directory to manage, when a path is not explicitly set.
#   This name must have a corresponding entry in TP data with
#   a key named ${base_dir}_dir_path.
#   The default 'config' value maps to the key config_dir_path
#
# @param path                      Default: undef
#   The actual path of the directory to manage.
#   If not explicitly defined, the managed path depends on the application name
#   set as title, the underlying OS, and the base_dir set.
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
# @param config_dir_notify         Default: true
#   By default changes in the managed dir trigger a service restart of the
#   app in the title. Set to false to avoid any restart of set the name of a Puppet
#   resource to notify. (Ex: Service[nginx])

# @param config_dir_require        Default: true,
#   By default the resource managed requires the app package, if tp::install has
#   not been used to install the app, you may have references to an unknown
#   resource. Set this to false to not set any dependency, or define a resource
#   to require before managing the dir (Ex: Package[apache2])
#
# @param purge                     Default: undef,
#   Parameter purge for the managed file resource.
#
# @param recurse                   Default: undef,
#   Parameter recurse for the managed file resource.
#
# @param settings_hash             Default: { }
#   An hash that can override the application specific settings returned
#   by tp according to the underlying Operating System
#
# @param force                     Default: undef,
#   Parameter force for the managed file resource.
#
# @param debug                     Default: false,
#   If set to true it prints debug information for tp into the directory set in
#   debug_dir
#
# @param debug_dir                 Default: '/tmp',
#   The directory where tp stores dbug info, when enabled
#
# @param data_module               Default: 'tinydata'
#   Name of the module where tp data is looked for
#
define tp::dir3 (

  $ensure               = 'present',

  $source               = undef,
  $vcsrepo              = undef,

  $base_dir             = 'config',

  $path                 = undef,
  $mode                 = undef,
  $owner                = undef,
  $group                = undef,

  $config_dir_notify    = true,
  $config_dir_require   = true,

  $purge                = undef,
  $recurse              = undef,
  $force                = undef,

  $settings_hash        = { } ,

  $debug                = false,
  $debug_dir            = '/tmp',

  $data_module          = 'tinydata',

  ) {

  # Parameters validation
  validate_bool($debug)


  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $dir = $title_elements[1]
  if $title =~ /^\/.*$/ {
    # If title is an absolute path do a safe lookup to
    # a dummy app
    $tp_settings = tp_lookup('test','settings',$data_module,'merge')
    $title_path = $title
  } else {
    $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
    $title_path = undef
  }
  $settings=merge($tp_settings,$settings_hash)

  $base_dir_path = $settings["${base_dir}_dir_path"]

  $manage_path    = tp_pick($path, $title_path, $base_dir_path)
  $manage_mode    = tp_pick($mode, $settings[config_dir_mode])
  $manage_owner   = tp_pick($owner, $settings[config_dir_owner])
  $manage_group   = tp_pick($group, $settings[config_dir_group])

  # Set require if package_name is present 
  if $settings[package_name] and $settings[package_name] != '' {
    $package_ref = "Package[${settings[package_name]}]"
  } else {
    $package_ref = undef
  }
  $manage_require = $config_dir_require ? {
    ''        => undef,
    false     => undef,
    true      => $package_ref,
    default   => $config_dir_require,
  }

  # Set notify if service_name is present 
  if $settings[service_name] and $settings[package_name] != '' {
    $service_ref = "Service[${settings[service_name]}]"
  } else {
    $service_ref = undef
  }
  $manage_notify  = $config_dir_notify ? {
    ''        => undef,
    false     => undef,
    true      => $service_ref,
    default   => $config_dir_notify,
  }

  $manage_ensure = $ensure ? {
    'present' => $vcsrepo ? {
      undef   => 'directory',
      default => 'present',
    },
    'absent' => 'absent',
  }

  # Finally, the resources managed
  if $vcsrepo {
    vcsrepo { $manage_path:
      ensure   => $manage_ensure,
      source   => $source,
      provider => $vcsrepo,
      owner    => $manage_owner,
      group    => $manage_group,
    }
  } else {
    file { $manage_path:
      ensure  => $manage_ensure,
      source  => $source,
      path    => $manage_path,
      mode    => $manage_mode,
      owner   => $manage_owner,
      group   => $manage_group,
      require => $manage_require,
      notify  => $manage_notify,
      recurse => $recurse,
      purge   => $purge,
      force   => $force,
    }
  }


  # Debugging
  if $debug == true {
    $debug_file_params = "
    vcsrepo { ${manage_path}:
      ensure   => ${manage_ensure},
      source   => ${source},
      provider => ${vcsrepo},
      owner    => ${manage_owner},
      group    => ${manage_group},
    }

    file { ${manage_path}:
      ensure  => ${manage_ensure},
      source  => ${source},
      path    => ${manage_path},
      mode    => ${manage_mode},
      owner   => ${manage_owner},
      group   => ${manage_group},
      require => ${manage_require},
      notify  => ${manage_notify},
      recurse => ${recurse},
      purge   => ${purge},
    }
    "
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    $manage_debug_content = "RESOURCE:\n${debug_file_params} \n\nSCOPE:\n${debug_scope}"

    file { "tp_dir_debug_${title}":
      ensure  => present,
      content => $manage_debug_content,
      path    => "${debug_dir}/tp_dir_debug_${title}",
    }
  }

}

