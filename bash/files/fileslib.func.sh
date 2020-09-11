import options

function fileslib-append-string() {
  eval "$(setSimpleOptions FILE_NAME NOT_PRESENT:P -- "$@")"

  local FILE="${1}"
  local LINE="${2}"
  touch "$FILE"
  grep "$LINE" "$FILE" > /dev/null || echo "$LINE" >> "$FILE"
}
