if [[ $(uname) == 'Darwin' ]]; then
  GNU_GETOPT="$(brew --prefix gnu-getopt)/bin/getopt"
else
  GNU_GETOPT="$(which getopt)"
fi

# Usage:
#   local TMP
#   TMP=$(setSimpleOptions SHORT LONG= SPECIFY_SHORT:X LONG_SPEC:S= -- "$@") \
#     || ( contextHelp; echoerrandexit "Bad options."; )
#   eval "$TMP"
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
    local VAR_NAME LOWER_NAME SHORT_OPT LONG_OPT
    if [[ "$VAR_SPEC" == '--' ]]; then
      break
    elif [[ "$VAR_SPEC" == *':'* ]]; then
      VAR_NAME=$(echo "$VAR_SPEC" | cut -d: -f1)
      SHORT_OPT=$(echo "$VAR_SPEC" | cut -d: -f2)
    else # each input is a variable name
      VAR_NAME="$VAR_SPEC"
      SHORT_OPT=$(echo "${VAR_NAME::1}" | tr '[:upper:]' '[:lower:]')
    fi
    local OPT_REQ=$(echo "$VAR_NAME" | sed -Ee 's/[^=]//g' | tr '=' ':')
    VAR_NAME=$(echo "$VAR_NAME" | tr -d "=")
    LOWER_NAME=$(echo "$VAR_NAME" | tr '[:upper:]' '[:lower:]')
    LONG_OPT="$(echo "${LOWER_NAME}" | tr '_' '-')"

    SHORT_OPTS="${SHORT_OPTS:-}${SHORT_OPT}${OPT_REQ}"

    LONG_OPTS=$( ( test ${#LONG_OPTS} -gt 0 && echo -n "${LONG_OPTS},") || true && echo -n "${LONG_OPT}${OPT_REQ}")

    LOCAL_DECLS="${LOCAL_DECLS:-}local ${VAR_NAME}='';"
    local VAR_SETTER="${VAR_NAME}=true;"
    if [[ -n "$OPT_REQ" ]]; then
      LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}_SET='';"
      VAR_SETTER=${VAR_NAME}'="${2}"; '${VAR_NAME}'_SET=true; shift;'
    fi
    CASE_HANDLER=$(cat <<EOF
    ${CASE_HANDLER}
      -${SHORT_OPT}|--${LONG_OPT}]
        $VAR_SETTER
        _OPTS_COUNT=\$(( \$_OPTS_COUNT + 1));;
EOF
)
  done # main while loop
  CASE_HANDLER=$(cat <<EOF
    case "\$1" in
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
  shift
done
shift
EOF
#  echo 'if [[ -z "$1" ]]; then shift; fi' # TODO: explain this
}
