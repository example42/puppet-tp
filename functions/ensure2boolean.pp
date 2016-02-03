function tp::ensure2boolean (
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
