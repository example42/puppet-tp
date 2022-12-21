# Function tp::fail.
# Gets an url and coverts is based on a given map
function tp::fail (
  Enum['fail','ignore','warn'] $data_fail_behaviour,
  String $message,
) {
  case $data_fail_behaviour {
    'alert': {
      alert($message)
    }
    'crit': {
      crit($message)
    }
    'debug': {
      debug($message)
    }
    'emerg': {
      emerg($message)
    }
    'err': {
      err($message)
    }
    'info': {
      info($message)
    }
    'notice': {
      notice($message)
    }
    'warning': {
      warning($message)
    }
    'notify': {
      notify { "tp_fail_${message}":
        message  => $message,
        loglevel => 'warning',
      }
    }
    default: {
      info($message)
    }
  }
}
