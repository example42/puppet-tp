# CHANGELOG

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
