# CHANGELOG

## 3.10.3
- Fix warnings

## 3.10.2

- Fixed options param in tp::conf where use_v4 is false
- Windows improvements

## 3.10.1

-   Changed CI containers used
-   Unit tests for Puppet 7 and 8
-   Lints and fix on undefined vars
-   Updated tp::create_dir

## 3.10.0

-   Added support for $MAJVERSION variable in tinydata
-   Added support for xz release files
-   Refactorings in install type management:
-   -   support for root and normal users
    -   install_type file renamed to release
    -   settings are computed in tp::install and used in tp::install::* defines
-   get_version and url_replace functions accept an addtional version type paramter
-   Widened support for variables in tinydata
-   Removed legacy facts for Puppet 8 compatibility

## 3.9.1

-   Fixed tp debug cli command
-   Fixed tp test command on apps without packages
-   Fixed possible resource duplicstion when multiple app with exec_postinstall setting are present in the catalog
-   Fixed repo keys managmeent when apt_safe_trusted_key is true
-   Updated metadata.json to reflect factual compatibility with only Puppet 6 or later
-   Updated metadata.json to have puppetlabs/vcsrepo as a dependency
-   Updated sample tinydata and OS tests in unit tests
-   Fixed tp uninstall command to remove also tp data files

## 3.9.0

-   tp::install::* defines simplified and aligned to semifinal v4 tinydata structure
-   Added function tp::get_version
-   Added function tp::title_replace
-   Changed lookup method to deep_merge to all tp_lookup function calls
-   Added define tp::copy_file
-   Added define tp::service
-   Added define tp::setup
-   Added data types to match v4 tinydata structures
-   Updated tp::dir to v4
-   Updated tp::file to v4

## 3.8.0

-   Added tp::use_v4 setting to use Puppet 4 compatible code
-   Added v4 code for tp, tp::install
-   Added tp::cli class to manage tp command in v4
-   Added tp::install::package to manage apps from packages
-   Added tp::install::file to download apps from release urls
-   Added tp::fail function and data type and on_missing_data setting
-   Added tp::url_replace and tp::create_everything functions
-   Separated all old code, files and templaes from v4 specific
-   Added tp::install::source to download apps from source repos
-   Added tp::install::image to download and install app container image
-   Params tp::tp_dir and tp::tp_path have been replaced by tp::tp_params and derived from identify fact 
-   Added v4 entrypoints for Hiera data driven tp resources: tp::<resource>s and tp::osfamily_resources
-   Deprecated the corresponding tp::<resource>_hash and tp::osfamily_<resource>_hash

## 3.7.0

-   tp desktop noapply command renamed to tp desktop preview
-   Added /usr/sbin/tp symbolic link to avoid errors due to incorrect PATH
-   Fixed tp::repo with setting repo_file_url
-   Fixed tp test with packages using pip3
-   Do not clone locally tp module when using tp desktop command
-   Added new settings: website_url, winget_package_name, choco_package_name, docker_image

## 3.6.2

-   Added tp debug command, define and task. Added debug_commands tinydata key.
-   Added tp desktop noapply command
-   Better management of tp global files when user is not privileged
-   Added support for scope in tp::conf and tp::dir
-   Added relevant user_ tinydata settings
-   Quote shellvars script
-   Fixed prerequisites dependencies when package_name is absent
-   Added tp source command and task

## 3.6.1

-   Fixed tp desktop show command
-   Show output of tp desktop apply command

## 3.6.0

-   Added shellvars data to shell scripts using tiny data.
-   Fixed tp info output
-   First prototype of tp desktop
-   Added define tp::source

## 3.5.3

-   Fix tp service test within docker containers

## 3.5.2

-   Fixed idempotency in keys management when tp::apt_safe_trusted_key is true

## 3.5.1

-   From Debian 11 and Ubuntu 22.04 upwards apt-key is no more used by default to manage apt keys.
    Keys are placed under /etc/apt/keyrings and trusted in the relevant source list files.
    If you upgrade tp and have Debian 11 and Ubuntu 22.04 servers where keys are already present,
    tp updates the trusted entry in the source list file but does not move existing keys from
    /etc/apt/trusted.gpg.d to /etc/apt/keyrings. You have to do it manually, naming the keyring gpg file as referenced in the source list.
    If you want to keep on using deprecated apt-key method to install keys also in these OS versions set on Hiera: tp::apt_safe_trusted_key: false
-   Added ensure parameter to tp class
-   Added support for Debian 11, SLES 15, Ubuntu 22.04
-   Fixed tinydata module path search when not using the official Puppet agent package
-   Added options to suppress annoying warnings or full output in tp install and uninstall commands
-   Fixed ruby interpreter path in tp command when not using the official Puppet agent package

## 3.5.0

-   Added ability to install from git_source in tp::install
-   Added git_use, git_destination and git_source settings
-   Added version_command setting and tp version subcommand
-   Added tp::version task
-   Fixed tp install command auto_prereq

## 3.4.0

-   Added tp info define, task and cli command
-   Added init_system setting
-   tp test output change
-   Added info_commands setting
-   Added yumrepo_params setting

## 3.3.0

-   Updated to latest pdk template
-   Added GitHub workflow for Merge Request
-   Massive linting based on Voxpupuli extra lint checks
-   Added brew_tap setting

## 3.2.0

-   Avoid usage of legacy tp_content function
-   Allow to specify an .epp file for tempalte param of tp::conf
-   Fix .epp template management in tp::conf
-   Correctly identify repo check in tp test command when repo file path is custom
-   Fix usage of custom templates when config_file_type is set in tinydata
-   Correctly handle $options in templates used by tp::conf
-   Better handle errors in tp command when tp module is not installed locally

## 3.1.0

-   Added support for custom tp tests not related to apps
-   Better handling of errors in tp command when tp module is missing

## 3.0.0

-   Added data in module. Supported only Puppet version 4.9 and later.

## 2.5.1

-   Added support for tinydata config_file_format setting
-   Added tp::osfamily_install_hash and tp::osfamily_conf_hash parameters
-   Allow to set defaults and lookup method for all \_hash parameters in tp class
-   Added tinydata extra_prerequisites and extra_postinstall params
-   tp_prerequisites can can a String, Array of Hash of tp installs

## 2.5.0

-   Added tinydata params git_source and git_destination to install apps from git source
-   Added param repo_file_url to install a repo directly from http url (Note: if using https, the repo webserver certificate must be valid and accepted by locally installed CAs certs).
-   Added  repo_description tinydata setting
-   Added support for puppet gem packages in tp test
-   Improved support for Windows
-   tp test now shows also tp managed repos

## 2.4.3

-   Added repo_description setting

## 2.4.2

-   Ensure we find tp command in task tp::test 
-   Propagate data_module var to tp defines used in tp::install 
-   pdk convert

## 2.4.1

-   Fix for tp::install when upstream_repo is missing in tinydata

## 2.4.0

-   Added upstream_repo option

## 2.3.5

-   Explicitly close open files in tp_lookup
-   Add purge_dirs argument to tp class

## 2.3.4

-   Added repo_exec_environment argument to tp::install

## 2.3.3

-   Updated README

## 2.3.2

-   Approved status request [MODULES-5811](https://tickets.puppetlabs.com/browse/MODULES-5811)
-   Skip danger in travis CI
-   any variables can be accepted for ensure of dir (#59)

## 2.3.1

-   Allow spaces in key for apt-key checks in tp::repo (#57)

## 2.3.0

-   Do not fail on missing tinydata, try to install homonimous package

## 2.2.1

-   Added support for tinydata settings repo_name and repo_filename in tp::repo 
-   Added support for tinydata settings config_file_params and config_dir_params
-   tp from command line Install cli integration by default

## 2.2.0

-   Added support for tinydata setting **repo_package_params** in tp::repo 
-   tp::repo just installs the release package if tinydata exists
-   Install via wget and dkpg release package from repo_package_url On Debian in tp::repo
-   Added support for package_params and service_params in tp::install

## 2.1.1

-   Add support for trust_server_cert and any extra option on tp::dir
-   Install_hash should support arrays (@logicminds)

## 2.1.0

-   Added validate_syntax option to tp::conf

## 2.0.4

-   Added task tp::test

## 2.0.1

-   Added more spec tests
-   Minor fixes

## 2.0.0

-   Removed Puppet3 defines
-   Class tp: Removed params: packages, services, files
-   Define tp::install: Params auto_prerequisites renamed to auto_prereq
-   More Puppet 4 language constructs
-   Removed pick_undef and tp_pick functions. Use stdlib pick_default
-   Removed tp::concat define
-   Main tp class refactored to use params pattern instead of data in modules for backwards compatibility
-   Refactored spec tests. Now is possible to test any tp define on any os on any app
-   Added tests for tp::test, tp::uninstall, tp::stdmod
