# tp::source
#
# Makes a git clone of the repository of the given app
#
define tp::source (

  Variant[Boolean,String] $ensure              = present,
  Variant[Undef,String]   $path                = undef,
  Variant[Undef,String]   $source              = undef,
  Variant[Undef,String]   $app                 = $title,

  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',
  String[1]               $destination_dir     = '/opt/src',

) {
  # Settings evaluation
  $tp_settings=tp_lookup($title,'settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  if $settings[git_source] or $source {
    tp::dir { $app:
      ensure  => $ensure,
      path    => pick($settings[git_destination], "${destination_dir}/${app}"),
      source  => pick($source,$settings[git_source]),
      vcsrepo => 'git',
    }
  }
}
