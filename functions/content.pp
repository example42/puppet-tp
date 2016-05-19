function tp::content (
  Any $local_content,
  Variant[Undef,String] $template,
  Variant[Undef,String] $epp_template,
) {

  if ::tp::is_something($local_content) {
    $output = $local_content
  } elsif ::tp::is_something($template) {
    $output = template($template)
  } elsif ::tp::is_something($epp_template) {
    $output = epp($epp_template)
  } else {
    $output = undef
  }

}
