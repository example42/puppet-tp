# Function tp::url_replace.
# Gets an url and coverts is based on a given map
function tp::url_replace (
  String $url,
  String $_version,
  Optional[String] $_majversion = undef,
) {
  # TODO: Improve and make dynamic when needed
  $translated_arch = $facts['os']['architecture'] ? {
    'x86_64' => 'amd64',
    'x64'    => 'amd64',
    'i386'   => '386',
    default  => pick_default($facts['os']['architecture'], ''),
  }
  $versioned_url = regsubst($url,'\$VERSION', $_version, 'G')
  if $_majversion == undef {
    $majversioned_url = $versioned_url
  } else {
    $majversioned_url = regsubst($versioned_url,'\$MAJVERSION', $_majversion, 'G')
  }
  $os_replaced_url = regsubst($majversioned_url,'\$OS', downcase($facts['kernel']), 'G')
  $arch_replaced_url = regsubst($os_replaced_url,'\$ARCH', downcase($translated_arch), 'G') # lint:ignore:140chars

  return $arch_replaced_url
}
