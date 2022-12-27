function tp::ensure2service (
  Variant[Boolean,String] $input  = present,
  Enum['ensure','enable'] $param = 'ensure',
) {
  $output = $param ? {
    'ensure' => $input ? {
      'absent'  => stopped,
      false     => stopped,
      default   => 'running',
    },
    'enable' => $input ? {
      'absent'  => false,
      false     => false,
      default   => true,
    }
  }
}
