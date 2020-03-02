# @define tp::dir
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
#   Common names for dir types are:
#    - config (default, it refers to the main configuraion directory of the app)
#    - conf (a conf.d style directory where to place configuration fragments)
#    - log (the logs dir, if exists)
#    - data (where application data is stored)
#
# @example management of apache main configuration directory:
#
#   tp::dir { 'apache':
#     source => 'puppet:///modules/site/apache/role/fe',
#   }
#
# @example management of apache logs directory:
#
#   tp::dir { 'apache::logs': # The logs name here is needed just to have an unique title
#     base_dir => 'log',
#     mode     => '0640',
#   }
#
# @example management of the directory set as title, with the purge enforcement
# that removes any local file not present on the source directory (Be careful
# with purge ad force params, they can delete files)
#
#   tp::dir { '/data/www/default':
#     source => 'puppet:///modules/site/apache/role/fe',
#     purge  => true,
#     force  => true,
#   }
#
# @example Create the content of a directory based on a source
#   from a vcs repo (git, hg, bzr, cvs, svn, p4)
#
#   tp::dir { '/etc/puppetlabs/code/environments/production':
#     source  => 'https://github.com/example42/psick',
#     vcsrepo => git,
#   }
#
# @example Create the content of a directory based on a vcs repo with
# with extra options (must be valid options for the chosen vcsrepo)
#
#   tp::dir { '/etc/puppetlabs/code/environments/production':
#     source          => 'https://git.internal/puppet/control-repo',
#     vcsrepo         => git,
#     vcsrepo_options => {
#       trust_server_cert => true,
#     }
#   }
#
# @param ensure Define the status of the directory: present or absent.
#
# @param source This sets the source content for the managed dir.
#   When the vcsrepo option is set it accepts any vcs tool's supported url.
#   For example: https://github.com/example42/puppet-tp 
#   By default a normal directory is managed, whose content may be
#   populated referring to a directory like: puppet:///modules/site/app/test/
#   This would refer to the content of the directory
#   $MODULEPATH/site/files/app/test/.
#
# @param vcsrepo If set the directory is managed via the vcsrepo resource.
#   vcsrepo options are bzr, cvs, git, hg, p4, svn
#   It requires a valid source parameter.
#
# @param vcsrepo_options An hash of parameters to pass to the vcsrepo define,
#   when used. This hash is merged with an internall built one based on 
#   the parameters: ensure, source, vcsrepo, owner and group
#
# @param base_dir Type of the directory to manage, when a path is not defined.
#   This name must have a corresponding entry in TP data with
#   a key named ${base_dir}_dir_path.
#   The default 'config' value maps to the key config_dir_path.
#
# @param path The actual path of the directory to manage.
#   If not explicitly defined, the managed path depends on the application name
#   set as title, the underlying OS, and the base_dir set.
#
# @param mode Parameter mode for the managed file resource.
#   By default is calculated by tp defined according to app and OS.
#
# @param owner Parameter owner for the managed file resource.
#   By default is calculated by tp defined according to app and OS.
#
# @param group Parameter group for the managed file resource.
#   By default is calculated by tp defined according to app and OS.
#
# @param config_dir_notify By default changes in the managed dir trigger a
#   service restart of the app in the title. Set to false to avoid restarts
#   or set the name of a Puppet resource to notify. (Ex: Service[nginx])
#
# @param config_dir_require By default the resource managed requires the app
#   package, if tp::install has not been used to install the app, you may have
#   references to an unknown resource. Set this to false to not set any
#   dependency, or define a resource to require before managing the dir
#   (Ex: Package[apache2]).
#
# @param purge Parameter purge for the managed file resource.
#   Set purge, force and recurse to true and ensure to absent to completely remove the
#   directory.
#
# @param recurse Parameter recurse for the managed file resource.
#
# @param force Parameter force for the managed file resource.
#
# @param settings_hash An hash that can override the application specific
#   settings returned by tp according to the underlying Operating System
#
# @param debug If set to true it prints debug information for tp into the
#   directory set in debug_dir
#
# @param debug_dir The directory where tp stores debug info, if enabled.
#
# @param data_module Name of the module where tp data is looked for
#  Default is tinydata: https://github.com/example42/tinydata
#
define tp::dir (

  String[1]              $ensure             = 'present',

  Variant[Undef,String,Array] $source        = undef,
  Variant[Undef,Boolean,String] $vcsrepo     = false,
  Hash                   $vcsrepo_options    = {},
  String[1]              $base_dir           = 'config',

  Variant[Undef,String]  $path               = undef,
  Variant[Undef,String]  $mode               = undef,
  Variant[Undef,String]  $owner              = undef,
  Variant[Undef,String]  $group              = undef,

  String                 $path_prefix         = '',
  Boolean                $path_parent_create  = false,

  Variant[Boolean,String] $config_dir_notify  = true,
  Variant[Boolean,String] $config_dir_require = true,

  Variant[Undef,Boolean] $purge              = undef,
  Variant[Undef,Boolean] $recurse            = undef,
  Variant[Undef,Boolean] $force              = undef,

  Hash                   $settings_hash      = { } ,

  Boolean                $debug               = false,
  String[1]              $debug_dir           = '/tmp',

  String[1]              $data_module        = 'tinydata',

  ) {

  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $dir = $title_elements[1]
  if $title =~ /^\/.*$/ {
    # If title is an absolute path do a safe lookup to
    # a dummy app
    $tp_settings = tp_lookup('test','settings','tinydata','merge')
    $title_path = $title
  } else {
    $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
    $title_path = undef
  }
  $settings = $tp_settings + $settings_hash
  $base_dir_path = $settings["${base_dir}_dir_path"]
  $real_path      = pick($path, $title_path, $base_dir_path)
  $manage_path    = "${path_prefix}${real_path}"
  $manage_mode    = pick($mode, $settings[config_dir_mode])
  $manage_owner   = pick($owner, $settings[config_dir_owner])
  $manage_group   = pick($group, $settings[config_dir_group])

  # Set require if package_name is present and title is not a abs path
  if $settings[package_name] and $settings[package_name] != ''
  and $title !~ /^\/.*$/ {
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

  # Set notify if service_name is present and title is not a abs path
  if $settings[service_name] and $settings[package_name] != ''
  and $title !~ /^\/.*$/ {
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

  $ensure_vcsrepo = $ensure ? {
    'directory' => 'present',
    default     => $ensure,
  }
  $ensure_dir = tp::ensure2dir($ensure)

  # Finally, the resources managed
  if $path_parent_create {
    $path_parent = dirname($manage_path)
    $exec_before = $vcsrepo ? {
      undef   => File[$manage_path],
      default => Vcsrepo[$manage_path],
    }
    exec { "mkdir for tp::dir ${title}":
      command => "/bin/mkdir -p ${path_parent}",
      creates => $path_parent,
      before  => $exec_before,
    }
  }

  if $vcsrepo {
    $vcsrepo_defaults = {
      ensure   => $ensure_vcsrepo,
      source   => $source,
      provider => $vcsrepo,
      owner    => $manage_owner,
      group    => $manage_group,
    }
    vcsrepo { $manage_path:
      * => $vcsrepo_defaults + $vcsrepo_options,
    }
  } else {
    $file_params = {
      ensure  => $ensure_dir,
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
    file { $manage_path:
      * => $file_params + pick($settings[config_dir_params],{})
    }
  }

  # Debugging
  if $debug == true {
    $debug_scope = inline_template('<%= scope.to_hash.reject { |k,v| k.to_s =~ /(uptime.*|path|timestamp|free|.*password.*)/ } %>')
    file { "tp_dir_debug_${title}":
      ensure  => $ensure,
      content => $debug_scope,
      path    => "${debug_dir}/tp_dir_debug_${title}",
    }
  }
}
