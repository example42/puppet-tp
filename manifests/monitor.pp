#
# = Define: tp::monitor
#
define tp::monitor (

  $ensure               = present,

  $tool                 = undef,

  $options_hash         = undef,

  $settings_hash        = undef,

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
  $tool = $title_elements[1]
  $settings = tp_lookup($app,'settings',$data_module,'merge')


}
