import echofmt

import colors
import options

echoerr() {
  echofmt --error "$@"
}

echowarn() {
  echofmt --warn "$@"
}

# Echoes a formatted message to STDERR. The default exit code is '1', but if 'EXIT_CODE', then that will be used. E.g.:
#
#    EXIT_CODE=5
#    echoerrandexit "Fatal code 5!"
#
# See echofmt for further options and details.
echoerrandexit() {
  echofmt --error "$@"

  [[ -z "${EXIT_CODE:-}" ]] || exit ${EXIT_CODE}
  exit 1
}
