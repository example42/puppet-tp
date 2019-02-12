# CHANGELOG

# 2.3.4
* Added repo_exec_environment argument to tp::install

# 2.3.3
* Updated README

# 2.3.2
* Approved status request [MODULES-5811] - https://tickets.puppetlabs.com/browse/MODULES-5811
* Skip danger in travis CI
* any variables can be accepted for ensure of dir (#59)

# 2.3.1
* Allow spaces in key for apt-key checks in tp::repo (#57)

# 2.3.0
* Do not fail on missing tinydata, try to install homonimous package

# 2.2.1
* Added support for tinydata settings repo_name and repo_filename in tp::repo 
* Added support for tinydata settings config_file_params and config_dir_params
* tp from command line Install cli integration by default

# 2.2.0
* Added support for tinydata setting [repo_package_params] in tp::repo 
* tp::repo just installs the release package if tinydata exists
* Install via wget and dkpg release package from repo_package_url On Debian in tp::repo
* Added support for package_params and service_params in tp::install

## 2.1.1

* [#52] Add support for trust_server_cert and any extra option on tp::dir
* [#44] Install_hash should support arrays [@logicminds]

## 2.1.0

* Added validate_syntax option to tp::conf

## 2.0.4

* Added task tp::test

## 2.0.1

* Added more spec tests
* Minor fixes

## 2.0.0

* Removed Puppet3 defines
* Class tp: Removed params: packages, services, files
* Define tp::install: Params auto_prerequisites renamed to auto_prereq
* More Puppet 4 language constructs
* Removed pick_undef and tp_pick functions. Use stdlib pick_default
* Removed tp::concat define
* Main tp class refactored to use params pattern instead of data in modules for backwards compatibility
* Refactored spec tests. Now is possible to test any tp define on any os on any app
* Added tests for tp::test, tp::uninstall, tp::stdmod
