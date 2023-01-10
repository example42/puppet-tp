# tp::source
#
# Makes a git clone of the repository of the given app
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

  if $settings[git_source] or $source {
    tp::dir { "${app} source":
      ensure          => $ensure,
      path            => pick($path, $settings[git_destination], "${destination_dir}/${app}"),
      source          => pick($source,$settings[git_source]),
      vcsrepo         => 'git',
      vcsrepo_options => $vcsrepo_options,
    }
  }
}
