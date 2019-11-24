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
    unset $VAR
    while true; do
      read -r LINE
      [[ "$LINE" == '.' ]] && break
      if [[ -z "$LINE" ]] && [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
        eval "${VAR}='$(echo "$DEFAULT" | sed "s/'/'\"'\"'/g")'"
        break
      fi
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

  # TODO: support 'pass-through' options in 'setSimpleOptions'
  local OPTS=''
  if [[ -n "$MULTI_LINE" ]]; then
    OPTS="${OPTS}--multi-line "
  fi
  while [[ -z ${!VAR:-} ]] || [[ -n "$FORCE" ]]; do
    get-answer ${OPTS} "$PROMPT" "$VAR" "$DEFAULT" # can't use "$@" because default may be overriden
    if [[ -z ${!VAR:-} ]]; then
      echoerr "A response is required."
    else
      FORCE='' # if forced into loop, then we un-force when we get an answer
    fi
  done
}

yes-no() {
  default-yes() { return 0; }
  default-no() { return 1; } # bash false-y

  local PROMPT="$1"
  local DEFAULT=$2
  local HANDLE_YES="${3:-default-yes}"
  local HANDLE_NO="${4:-default-no}" # default to noop

  local ANSWER=''
  read -p "$PROMPT" ANSWER
  if [ -z "$ANSWER" ]; then
    case "$DEFAULT" in
      Y*|y*)
        $HANDLE_YES; return $?;;
      N*|n*)
        $HANDLE_NO; return $?;;
      *)
        echo "You must choose an answer."
        yes-no "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO
    esac
  else
    case "$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')" in
      y|yes)
        $HANDLE_YES; return $?;;
      n|no)
        $HANDLE_NO; return $?;;
      *)
        echo "Did not understand response, please answer 'y(es)' or 'n(o)'."
        yes-no "$PROMPT" "$DEFAULT" $HANDLE_YES $HANDLE_NO;;
    esac
  fi
}

gather-answers() {
  eval "$(setSimpleOptions VERIFY PROMPTER= -- "$@")"
  local FIELDS="${1}"

  local FIELD VERIFIED
  while [[ "${VERIFIED}" != true ]]; do
    # collect answers
    for FIELD in $FIELDS; do
      local OPTS=''
      # if VERIFIED is set, but false, then we need to force require-answer to set the var
      [[ "$VERIFIED" == false ]] && OPTS='--force '
      if [[ "${FIELD}" == *: ]]; then
        FIELD=${FIELD/%:/}
        OPTS="${OPTS}--multi-line "
      fi
      local LABEL="$FIELD"
      $(tr '[:lower:]' '[:upper:]' <<< ${foo:0:1})${foo:1}
      LABEL="${LABEL:0:1}$(echo "${LABEL:1}" | tr '[:upper:]' '[:lower:]' | tr '_' ' ')"
      local PROMPT
      PROMPT="$({ [[ -n "$PROMPTER" ]] && $PROMPTER "$FIELD" "$LABEL"; } || echo "${LABEL}: ")"
      require-answer ${OPTS} "${PROMPT}" $FIELD
    done

    # verify, as necessary
    if [[ -z "${VERIFY}" ]]; then
      VERIFIED=true
    else
      verify() { VERIFIED=true; }
      no-verify() { VERIFIED=false; }
      echo
      echo "Verify the following:"
      for FIELD in $FIELDS; do
        echo "$FIELD: ${!FIELD}"
      done
      echo
      yes-no "Are these values correct? (y/N) " N verify no-verify
    fi
  done
}
