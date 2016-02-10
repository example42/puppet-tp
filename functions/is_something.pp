function tp::is_something (
  Any $input,
) {

  $output = $input ? {
    false     => false,
    ''        => false,
    []        => false,
    {}        => false,
    undef     => false,
    default   => true,
  }

}
