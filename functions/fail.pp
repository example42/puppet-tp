# Function tp::fail.
# Uses the approach provided via the first argument to manage the notification
# of the message in the second argument
function tp::fail (
  Tp::Fail $on_missing_data,
  String $message,
) {
  case $on_missing_data {
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
    'ignore': {
      # do nothing
    }
    default: {
      info($message)
    }
  }
}
