function tp::ensure2bool (
  Variant[Boolean,String] $input  = present,
  $default = undef,
) {

  $output = $input ? {
    'absent'  => false,
    false     => false,
    'present' => true,
    true      => true,
    default   => $default,
  }

}
