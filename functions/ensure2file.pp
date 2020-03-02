function tp::ensure2file (
  Variant[Boolean,String] $input  = present,
) {

  $output = $input ? {
    'absent'  => absent,
    false     => absent,
    default   => present,
  }

}
