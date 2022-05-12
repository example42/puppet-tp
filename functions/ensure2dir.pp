function tp::ensure2dir (
  Variant[Boolean,String] $input  = present,
) {
  $output = $input ? {
    'absent'  => absent,
    false     => absent,
    default   => 'directory',
  }
}
