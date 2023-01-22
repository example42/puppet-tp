# Function tp::title_replace.
# Gets a string the a $TITLE placeholder and coverts it based on the given title.
function tp::title_replace (
  Variant[String,Undef] $input,
  String $_app,
) {
  if $input == undef {
    return undef
  } else {
    $replaced_title = regsubst($input,'\$TITLE', $_app, 'G')
    return $replaced_title
  }
}
