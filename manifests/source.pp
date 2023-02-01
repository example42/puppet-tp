# @define tp::source Clone the git repository of the source code of the given app
#
# Makes a git clone of the repository of the given app or of what's has been specified
# in the $source paramater
#
# @param ensure If to clone the repository or remove it
#
# @param path Path where to clone the repository
#
# @param source URL of the git repository to clone, if not set tinydata, if present
#   is going to be used: v4 setting: urls.source. v3 setting: git_source
#
# @param app Name of the app to clone the repository of
#
# @param my_settings Custom settings to merge with the settings from tinydata
#
# @param vcsrepo_options Options to pass to the vcsrepo resource used when cloning
#   the source
#
# @param data_module The name of the tinydata module to use
#
# @param destination_dir The directory where to clone the repository if no path is
#   specified the default is /opt/src
#
define tp::source (

  Variant[Boolean,String] $ensure              = present,
  Variant[Undef,String]   $path                = undef,
  Variant[Undef,String]   $source              = undef,
  Variant[Undef,String]   $app                 = $title,

  Hash                    $my_settings         = {},
  Hash                    $vcsrepo_options     = {},
  String[1]               $data_module         = 'tinydata',
  String[1]               $destination_dir     = '/opt/src',

) {
  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'deep_merge')
  $settings = $tp_settings + $my_settings

  $real_source = pick_default($source,getvar('settings.urls.source'),getvar('settings.git_source'))

  if $real_source {
    tp::dir { "${app} source":
      ensure          => $ensure,
      path            => pick($path, $settings[git_destination], "${destination_dir}/${app}"),
      source          => $real_source,
      vcsrepo         => 'git',
      vcsrepo_options => $vcsrepo_options,
    }
  }
}
