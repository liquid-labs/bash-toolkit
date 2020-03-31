import echoerr
import lists
import options
import stringlib

# Prompts the user for input and saves it to a var.
# Arg 1: The prompt.
# Arg 2: The name of the var to save the answer to. (BUG: Don't use 'VAR'. 'ANSWER' is always safe.)
# Arg 3 (opt): Default value to use if the user just hits enter.
#
# The defult value will be added to the prompt.
# If '--multi-line' is specified, the user may enter multiple lines, and end input with a line containing a single '.'.
# Instructions to this effect will emitted. Also, in this mode, spaces in the answer will be preserved, while in
# 'single line' mode, leading and trailing spaces will be removed.
get-answer() {
  eval "$(setSimpleOptions MULTI_LINE -- "$@")"
  local PROMPT="$1"
  local VAR="$2" # TODO: if name is 'VAR', then this breaks...
  local DEFAULT="${3:-}"

  if [[ -n "${DEFAULT}" ]]; then
    if [[ -z "$MULTI_LINE" ]]; then
      PROMPT="${PROMPT} (${DEFAULT}) "
    else
      PROMPT="${PROMPT}"$'\n''(Hit "<PERIOD><ENTER>" for default:'$'\n'"$DEFAULT"$'\n'')'
    fi
  fi

  if [[ -z "$MULTI_LINE" ]]; then
    read -r -p "$PROMPT" $VAR
    if [[ -z ${!VAR:-} ]] && [[ -n "$DEFAULT" ]]; then
      # MacOS dosen't support 'declare -g' :(
      eval $VAR='"$DEFAULT"'
    fi
  else
    local LINE
    echo "$PROMPT"
    echo "(End multi-line input with single '.')"
    unset $VAR LINE
    while true; do
      IFS= read -r LINE
      if [[ "$LINE" == '.' ]]; then
        if [[ -z "${!VAR:-}" ]] && [[ -n "$DEFAULT" ]]; then
          eval $VAR='"$DEFAULT"'
        fi
        break
      else
        list-add-item $VAR "$LINE"
      fi
    done
  fi
}

# Functions as 'get-answer', but will continually propmt the user if no answer is given.
# '--force' causes the default to be set to the previous answer and the query to be run again. This is mainly useful
# internally and direct calls should generally note have cause to use this option. (TODO: let's rewrite this to 'unset'
# the vars (?) and avoid the need for force?)
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

# Produces a 'yes/no' prompt, accepting 'y', 'yes', 'n', or 'no' (case insensitive). Unlike other prompts, this function
# returns true or false, making it convenient for boolean tests.
yes-no() {
  default-yes() { return 0; }
  default-no() { return 1; } # bash false-y

  local PROMPT="$1"
  local DEFAULT="${2:-}"
  local HANDLE_YES="${3:-default-yes}"
  local HANDLE_NO="${4:-default-no}" # default to noop

  local ANSWER=''
  read -p "$PROMPT" ANSWER
  if [[ -z "$ANSWER" ]] && [[ -n "$DEFAULT" ]]; then
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
  eval "$(setSimpleOptions VERIFY PROMPTER= SELECTOR= DEFAULTER= -- "$@")"
  local FIELDS="${1}"

  local FIELD VERIFIED
  while [[ "${VERIFIED}" != true ]]; do
    # collect answers
    for FIELD in $FIELDS; do
      local LABEL
      LABEL="$(field-to-label "$FIELD")"

      local PROMPT DEFAULT SELECT_OPTS
      PROMPT="$({ [[ -n "$PROMPTER" ]] && $PROMPTER "$FIELD" "$LABEL"; } || echo "${LABEL}: ")"
      DEFAULT="$({ [[ -n "$DEFAULTER" ]] && $DEFAULTER "$FIELD"; } || echo '')"
      if [[ -n "$SELECTOR" ]] && SELECT_OPS="$($SELECTOR "$FIELD")" && [[ -n "$SELECT_OPS" ]]; then
        local FIELD_SET="${FIELD}_SET"
        if [[ -z ${!FIELD:-} ]] && [[ "${!FIELD_SET}" != 'true' ]] || [[ "$VERIFIED" == false ]]; then
          PS3="${PROMPT}"
          selectDoneCancel "$FIELD" SELECT_OPS
          unset PS3
        fi
      else
        local OPTS=''
        # if VERIFIED is set, but false, then we need to force require-answer to set the var
        [[ "$VERIFIED" == false ]] && OPTS='--force '
        if [[ "${FIELD}" == *: ]]; then
          FIELD=${FIELD/%:/}
          OPTS="${OPTS}--multi-line "
        fi

        require-answer ${OPTS} "${PROMPT}" $FIELD "$DEFAULT"
      fi
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
        FIELD=${FIELD/:/}
        echo-label-and-values "${FIELD}" "${!FIELD:-}"
      done
      echo
      yes-no "Are these values correct? (y/N) " N verify no-verify
    fi
  done
}
