# Function tp::title_replace.
# Gets a string the a $TITLE placeholder and coverts it based on the given title.
function tp::title_replace (
  String $input,
  String $_app,
) {
  $replaced_title = regsubst($input,'\$TITLE', $_app, 'G')
  return $replaced_title
}
