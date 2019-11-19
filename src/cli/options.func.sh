import lists

if [[ $(uname) == 'Darwin' ]]; then
  GNU_GETOPT="$(brew --prefix gnu-getopt)/bin/getopt"
else
  GNU_GETOPT="$(which getopt)"
fi

# Usage:
#   eval "$(setSimpleOptions SHORT LONG= SPECIFY_SHORT:X LONG_SPEC:S= -- "$@")" \
#     || ( contextHelp; echoerrandexit "Bad options."; )
#
# Note the use of the intermediate TMP is important to preserve the exit value
# setSimpleOptions. E.g., doing 'eval "$(setSimpleOptions ...)"' will work fine,
# but because the last statement is the eval of the results, and not the function
# call itself, the return of setSimpleOptions gets lost.
#
# Instead, it's generally recommended to be strict, 'set -e', and use the TMP-form.
setSimpleOptions() {
  local VAR_SPEC LOCAL_DECLS
  local LONG_OPTS=""
  local SHORT_OPTS=""
  local _PASSTHRU=""
  # Bash Bug? This looks like a straight up bug in bash, but the left-paren in
  # '--)' was matching the '$(' and causing a syntax error. So we use ']' and
  # replace it later.
  local CASE_HANDLER=$(cat <<EOF
    --]
      break;;
EOF
)
  while true; do
    if (( $# == 0 )); then
      echoerrandexit "setSimpleOptions: No argument to process; did you forget to include the '--' marker?"
    fi
    VAR_SPEC="$1"; shift
    local VAR_NAME LOWER_NAME SHORT_OPT LONG_OPT IS_PASSTHRU
    IS_PASSTHRU=''
    if [[ "$VAR_SPEC" == *'^' ]]; then
      IS_PASSTHRU=true
      VAR_SPEC=${VAR_SPEC/%^/}
    fi
    local OPT_ARG=''
    if [[ "$VAR_SPEC" == *'=' ]]; then
      OPT_ARG=':'
      VAR_SPEC=${VAR_SPEC/%=/}
    fi

    if [[ "$VAR_SPEC" == '--' ]]; then
      break
    elif [[ "$VAR_SPEC" == *':'* ]]; then
      VAR_NAME=$(echo "$VAR_SPEC" | cut -d: -f1)
      SHORT_OPT=$(echo "$VAR_SPEC" | cut -d: -f2)
    else # each input is a variable name
      VAR_NAME="$VAR_SPEC"
      SHORT_OPT=$(echo "${VAR_NAME::1}" | tr '[:upper:]' '[:lower:]')
    fi

    VAR_NAME=$(echo "$VAR_NAME" | tr -d "=")
    LOWER_NAME=$(echo "$VAR_NAME" | tr '[:upper:]' '[:lower:]')
    LONG_OPT="$(echo "${LOWER_NAME}" | tr '_' '-')"

    if [[ -n "${SHORT_OPT}" ]]; then
      SHORT_OPTS="${SHORT_OPTS:-}${SHORT_OPT}${OPT_ARG}"
    fi

    LONG_OPTS=$( ( test ${#LONG_OPTS} -gt 0 && echo -n "${LONG_OPTS},") || true && echo -n "${LONG_OPT}${OPT_ARG}")

    LOCAL_DECLS="${LOCAL_DECLS:-}local ${VAR_NAME}='';"
    local CASE_SELECT="-${SHORT_OPT}|--${LONG_OPT}]"
    if [[ "$IS_PASSTHRU" == true ]]; then # handle passthru
      CASE_HANDLER=$(cat <<EOF
        ${CASE_HANDLER}
          ${CASE_SELECT}
          list-add-item _PASSTHRU "\$1"
EOF
      )
      if [[ -n "$OPT_ARG" ]]; then
        CASE_HANDLER=$(cat <<EOF
          ${CASE_HANDLER}
            list-add-item _PASSTHRU "\$2"
            shift
EOF
        )
      fi
      CASE_HANDLER=$(cat <<EOF
        ${CASE_HANDLER}
          shift;;
EOF
      )
    else # non-passthru vars
      local VAR_SETTER="${VAR_NAME}=true;"
      if [[ -n "$OPT_ARG" ]]; then
        LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}_SET='';"
        VAR_SETTER=${VAR_NAME}'="${2}"; '${VAR_NAME}'_SET=true; shift;'
      fi
      if [[ -z "$SHORT_OPT" ]]; then
        CASE_SELECT="--${LONG_OPT}]"
      fi
      CASE_HANDLER=$(cat <<EOF
      ${CASE_HANDLER}
        ${CASE_SELECT}
          $VAR_SETTER
          _OPTS_COUNT=\$(( \$_OPTS_COUNT + 1))
          shift;;
EOF
      )
    fi
  done # main while loop
  CASE_HANDLER=$(cat <<EOF
    case "\${1}" in
      $CASE_HANDLER
    esac
EOF
)
  # replace the ']'; see 'Bash Bug?' above
  CASE_HANDLER=$(echo "$CASE_HANDLER" | perl -pe 's/\]$/)/')

  echo "$LOCAL_DECLS"

  cat <<EOF
local TMP # see https://unix.stackexchange.com/a/88338/84520
TMP=\$(${GNU_GETOPT} -o "${SHORT_OPTS}" -l "${LONG_OPTS}" -- "\$@") \
  || exit \$?
eval set -- "\$TMP"
local _OPTS_COUNT=0
while true; do
  $CASE_HANDLER
done
shift
if [[ -n "\$_PASSTHRU" ]]; then
  eval set -- \$(list-quote _PASSTHRU) "\$@"
fi
EOF
}
