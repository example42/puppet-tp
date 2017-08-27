# CHANGELOG

## 2.0
### Changed:
* Removed Puppet3 defines
* Class tp: Removed params: packages, services, files
* Removed debug params from all the defines
* Define tp::install: Params auto_prerequisites renamed to auto_prereq
* More Puppet 4 language constructs
* Removed pick_undef and tp_pick functions. Use stdlib pick_default
* Removed tp::concat define
