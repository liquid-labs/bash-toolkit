import echoerr
import lists
import options

get-answer() {
  eval "$(setSimpleOptions MULTI_LINE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

  if [[ -n "${DEFAULT}" ]]; then
    PROMPT="${PROMPT} (${DEFAULT}) "
  fi

  if [[ -z "$MULTI_LINE" ]]; then
    read -r -p "$PROMPT" $VAR
    if [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
      # MacOS dosen't support 'declare -g' :(
      eval "${VAR}='$(echo "$DEFAULT" | sed "s/'/'\"'\"'/g")'"
    fi
  else
    local LINE
    echo "${green_bu}End multi-line input with single '.'${reset}"
    echo "$PROMPT"
    while true; do
      read -r LINE
      [[ "$LINE" == '.' ]] && break
      list-add-item $VAR "$LINE"
    done
  fi
}

require-answer() {
  eval "$(setSimpleOptions FORCE MULTI_LINE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

  if [[ -n "$FORCE" ]] && [[ -z "$DEFAULT" ]]; then
    DEFAULT="${!VAR}"
  fi

  if [[ -n "${DEFAULT}" ]]; then
    PROMPT="${PROMPT} (${DEFAULT}) "
  fi

  while [[ -z ${!VAR:-} ]] || [[ -n "$FORCE" ]]; do
    read -r -p "$PROMPT" $VAR
    if [[ -z ${!VAR:-} ]] && [[ -z "$DEFAULT" ]]; then
      echoerr "A response is required."
    elif [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
      # MacOS dosen't support 'declare -g' :(
      eval "${VAR}='$(echo "$DEFAULT" | sed "s/'/'\"'\"'/g")'"
      FORCE=''
    elif [[ -n "${!VAR:-}" ]] && [[ -n "$FORCE" ]]; then
      FORCE=''
    fi
  done
}
