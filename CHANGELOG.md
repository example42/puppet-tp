# CHANGELOG

## 2.0
### Changed:
* Removed Puppet3 defines
* Class tp: Removed params: packages, services, files
* Define tp::install: Removed param: debug_dir
* Define tp::install: Params auto_prerequisites renamed to auto_prereq
* More Puppet 4 language constructs
* Removed pick_undef function. Use pick(...,undef) instead.
