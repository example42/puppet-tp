#
# = Define: tp::monitor
#
define tp::monitor (

  Variant[Boolean,String] $ensure           = present,

  Hash                    $tools_hash       = { },
  Hash                    $options_hash     = { },
  Hash                    $settings_hash    = { },
  Hash                    $templates_hash   = { },

  Boolean                 $auto_repo        = true,

  Boolean                 $debug            = false,
  String[1]               $debug_dir        = '/tmp',

  String[1]               $data_module      = 'tinydata',

  ) {

  # Settings evaluation
  $title_elements = split ($title, '::')
  $app = $title_elements[0]
  $tool = $title_elements[1]
  $settings = tp_lookup($app,'settings',$data_module,'merge')

  ## TODO: Implement interfaces

}
