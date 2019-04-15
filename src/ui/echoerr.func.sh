import colors

echoerr() {
  echo -e "${red}$*${reset}" | fold -sw 82 >&2
}

echowarn() {
  echo -e "${yellow}$*${reset}" | fold -sw 82 >&2
}

echoerrandexit() {
  local MSG="$1"
  local EXIT_CODE="${2:-10}"
  echoerr "$MSG"
  exit $EXIT_CODE
}
