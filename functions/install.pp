# This function runs the tp::install define trying
# to avoid duplicated resources issues the tp::install
# may be declared multiple times (with same parameters)
# It is equivalent to the tp_install function, written in Ruby
#
function tp::install (
  String $app,
  Hash   $params = { },
) {

  if ! defined_with_params(Tp::Install[$app], $params ) {
    tp::install { $app:
      * => $params,
    }
  }

}
