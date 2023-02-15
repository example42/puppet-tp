# @define tp::install::source
#
# This define installs the application (app) set in the given title git cloning
# the relevant source and eventually building or installing elements from it.
# The define takes care of:
# - Cloning the app git repo from the Internet (git_source setting is used)
# - Eventually building sources
# - Eventually installing the app's binary to destination path
# - Eventually create and manage the relevant service
#
# This define is declared from the tp::install define when $install_method is set
# to 'source' either via a params entry or directly in tinydata settings.
#
# @param ensure If to install (present), remove (absent), ensure is at a
#   specific ref (tag, branch or ) (1.1.1). Note: version can also be specified
#   via the version parameter. If that's set that takes prececendence over this one.
#
# @param on_missing_data What to do if tinydata is missing. Valid values are: ('emerg','')
#
# @param tp_params The tp_params hash to use. If not set, the global $tp::tp_params
#   is used.
#
# @param my_settings Custom settings hash. It's merged with and can
#   override the default tinydata settings key for the managed app
#
# @param auto_prereq If to automatically install the app's prerequisites
#   (if defined in tinydata)
#
# @param version The version to install. If not set, what's set in the ensure
#   parameter is used
#
# @param source The source URL to download the app from. If not set, the
#   URL is taken from tinydata
#
# @param owner The owner of the app's downloaded and extracted files
#
# @param group The group of the app's downloaded and extracted files
#
# @example Install an app from a release package. (Tinydaya must be present)
#   tp::install { 'prometheus':
#     install_method => 'release',
#   }
#
define tp::install::source (
  Variant[Boolean,String] $ensure           = present,

  Tp::Fail $on_missing_data = pick(getvar('tp::on_missing_data'),'notify'),

  Hash $tp_params                             = pick($tp::tp_params, {}),
  Hash $settings                              = {},

  Boolean $auto_prereq                        = pick($tp::auto_prereq, false),

  Optional[String]               $version     = undef,
  Optional[String]               $source      = undef,
  String[1] $owner = pick(getvar('identity.user'),'root'),
  String[1] $group = pick(getvar('identity.group'),'root'),

) {
  $app = $title
  $sane_app = regsubst($app, '/', '_', 'G')
  $destination = getvar('settings.destination')

  $tp_dir          = $tp::real_tp_params['conf']['path']
  $real_source = $ensure ? {
    'absent' => false,
    default  => pick($source,getvar('settings.urls.source'),getvar('settings.git_source'), false),
  }

  # Automatic dependencies management, if data defined
  if $auto_prereq and getvar('settings.build.prerequisites') and $ensure != 'absent' {
    tp::create_everything ( getvar('settings.build.prerequisites'), {})
  }

  if $real_source {
    tp::source { $app:
      ensure          => $ensure,
      source          => $real_source,
      path            => $destination,
      vcsrepo_options => delete_undef_values({
          revision => $version,
      }),
    }

  } else {
    tp::fail($on_missing_data, "tp::install::source ${app} - Missing parameter source or tinydata: settings.git_url") # lint:ignore:140chars
  }
}
