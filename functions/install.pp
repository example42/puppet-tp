function tp::install (
  String $app,
  Hash   $params = { },
) {

  if ! defined_with_params(Tp::Install[$app], $params ) {
    tp::install { $app:
      * => $params,
    }
  }

}
