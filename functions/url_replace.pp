# Function tp::url_replace.
# Gets an url and coverts is based on a given map
function tp::url_replace (
  String $url,
  String $_version,
) {
  # TODO: Improve and make dynamic when needed
  $translated_arch = $facts['os']['architecture'] ? {
    'x86_64' => 'amd64',
    'x64'    => 'amd64',
    'i386'   => '386',
    default  => $facts['os']['architecture'],
  }
  $versioned_url = regsubst($url,'\$VERSION', $_version, 'G')
  $os_replaced_url = regsubst($versioned_url,'\$OS', downcase($facts['kernel']), 'G')
  $arch_replaced_url = regsubst($os_replaced_url,'\$ARCH', downcase($translated_arch), 'G') # lint:ignore:140chars

  return $arch_replaced_url
}
