function tp::is_empty (
  Any $input,
) {

  $output = $input ? {
    false     => true,
    ''        => true,
    undef     => true,
    default   => false,
  }

}
