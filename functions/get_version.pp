# Function tp::get_version.
# Get the package version based on input
function tp::get_version (
  String $_ensure = '',
  Optional[String] $_version = undef,
  Hash $_settings = {},
  Enum['full', 'major'] $_version_type = 'full',
) {
  if $_version_type == 'major' {
    $real_version = pick_default(getvar('_settings.release.latest_version_major'))
  } elsif $_version != undef and $_ensure != 'absent' {
    $real_version = $_version
  } elsif $_ensure !~ /^present$|^latest$|^absent$/ {
    $real_version = $_ensure
  } elsif getvar('_settings.release.latest_version') {
    $real_version = getvar('_settings.release.latest_version')
  } else {
    $real_version = ''
  }

  return $real_version
}
