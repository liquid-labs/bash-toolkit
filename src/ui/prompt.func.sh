import echoerr
import options

require-answer() {
  eval "$(setSimpleOptions FORCE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

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
      unset FORCE
    elif [[ -n "${!VAR:-}" ]] && [[ -n "$FORCE" ]]; then
      unset FORCE
    fi
  done
}
