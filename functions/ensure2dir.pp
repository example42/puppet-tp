function tp::ensure2dir (
  Variant[Boolean,String] $input  = present,
  $default = undef,
) {

  $output = $input ? {
    'absent'  => absent,
    false     => absent,
    default   => 'directory',
  }

}
