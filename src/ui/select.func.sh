# You have two options when passing in the options to any of the select
# functions. You can separate each item by space and use quotes, such as:
#
# selectOneCancel RESULT option1 "option with space"
#
# Or you can embed newlines in the option string, such as:
#
# OPTIONS="option1
# option with space"
# selectOneCancel RESULT "$OPTIONS"
#
# The second method can be combined with 'list-add-item' to safely build up
# options (which may contain spaces) dynamically. The two methods cannot be
# combined and the presece of a newline in any option will cause the input to
# interepretted by the second method.

import lists

_commonSelectHelper() {
  # TODO: the '_' is to avoid collision, but is a bit hacky; in particular, some callers were using 'local OPTIONS'
  # TODO TODO: when declared local here, it should not change the caller... I tihnk the original analysis was flawed.
  local _SELECT_LIMIT="$1"; shift
  local _VAR_NAME="$1"; shift
  local _PRE_OPTS="$1"; shift
  local _POST_OPTS="$1"; shift
  local _SELECTION
  local _QUIT='false'

  local _ENUM_OPTIONS
  if [[ "$@" == *$'\n'* ]]; then
    _ENUM_OPTIONS="$@"
  else
    while (( $# > 0 )); do
      local OPT="$1"; shift
      local DEFAULT
      # This is another quote preserving technique. We expect 'SELECT_DEFAULT'
      # might be "'foo bar' 'baz'".
      eval 'for DEFAULT in '${SELECT_DEFAULT:-}'; do
        if [[ "$DEFAULT" == "$OPT" ]]; then
          OPT="*${OPT}"
        fi
      done'

      list-add-item _ENUM_OPTIONS "$OPT" "\n"
    done
  fi

  local _OPTIONS="$_ENUM_OPTIONS"
  if [[ -n "$_PRE_OPTS" ]]; then
    _OPTIONS="$(echo "$_PRE_OPTS" | tr ' ' '\n')"$'\n'"$_OPTIONS"
  fi
  if [[ -n "$_POST_OPTS" ]]; then
    _OPTIONS="$_OPTIONS"$'\n'"$(echo "$_POST_OPTS" | tr ' ' '\n')"
  fi

  updateVar() {
    _SELECTION="$(echo "$_SELECTION" | sed -Ee 's/^\*//')"
    if [[ -z "${!_VAR_NAME:-}" ]]; then
      eval "${_VAR_NAME}='${_SELECTION}'"
    else
      eval "$_VAR_NAME='${!_VAR_NAME} ${_SELECTION}'"
    fi
    _SELECTED_COUNT=$(( $_SELECTED_COUNT + 1 ))
  }

  local _SELECTED_COUNT=0

  while [[ $_QUIT == 'false' ]]; do
    local OLDIFS="$IFS"
    IFS=$'\n'
    select _SELECTION in $_OPTIONS; do
      case "$_SELECTION" in
        '<cancel>')
          exit;;
        '<done>')
          _QUIT='true';;
        '<other>')
          _SELECTION=''
          requireAnswer "$PS3" _SELECTION "$_DEFAULT"
          updateVar;;
        '<any>')
          eval $_VAR_NAME='any'
          _QUIT='true';;
        '<all>')
          eval "$_VAR_NAME='$(echo $_ENUM_OPTIONS | tr '\n' ' ')'"
          _QUIT='true';;
        '<default>')
          eval "${_VAR_NAME}=\"${SELECT_DEFAULT}\""
          _QUIT='true';;
        *)
          updateVar;;
      esac

      # after first selection, 'default' is nullified
      SELECT_DEFAULT=''
      _OPTIONS=$(echo "$_OPTIONS" | sed -Ee 's/(^|\n)<default>(\n|$)//' | tr -d '*')

      if [[ -n "$_SELECT_LIMIT" ]] && (( $_SELECT_LIMIT >= $_SELECTED_COUNT )); then
        _QUIT='true'
      fi
      if [[ "$_QUIT" != 'true' ]]; then
        echo "Current selections: ${!_VAR_NAME}"
      else
        echo "Final selections: ${!_VAR_NAME}"
      fi
      # remove the just selected option
      _OPTIONS=${_OPTIONS/$_SELECTION/}
      _OPTIONS=${_OPTIONS//$'\n'$'\n'/$'\n'}

      # if we only have the default options left, then we're done
      local EMPTY_TEST # sed inherently matches lines, not strings
      EMPTY_TEST=`echo "$_OPTIONS" | sed -Ee 's/^(<done>)?\n?(<cancel>)?\n?(<all>)?\n?(<any>)?\n?(<default>)?\n?(<other>)?$//'`

      if [[ -z "$EMPTY_TEST" ]]; then
        _QUIT='true'
      fi
      break
    done # end select
    IFS="$OLDIFS"
  done
}

selectOneCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper 1 "$VAR_NAME" '<cancel>' '' "$@"
}

selectOneCancelDefault() {
  local VAR_NAME="$1"; shift
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectOneCancel "$VAR_NAME" "$@"
  else
    _commonSelectHelper 1 "$VAR_NAME" '<cancel>' '<default>' "$@"
  fi
}

selectOneCancelOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper 1 "$VAR_NAME" '<cancel>' '<other>' "$@"
}

selectCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<cancel>' '' "$@"
}

selectDoneCancel() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '' "$@"
}

selectDoneCancelAllOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<all> <other>' "$@"
}

selectDoneCancelAnyOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<any> <other>' "$@"
}

selectDoneCancelOther() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<other>' "$@"
}

selectDoneCancelOtherDefault() {
  local VAR_NAME="$1"; shift
  if [[ -z "$SELECT_DEFAULT" ]]; then
    echowarn "Requested 'default' select, but no default provided. Falling back to non-default selection."
    selectDoneCancelOther "$VAR_NAME" "$@"
  else
    _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<other> <default>' "$@"
  fi
}

selectDoneCancelAll() {
  local VAR_NAME="$1"; shift
  _commonSelectHelper '' "$VAR_NAME" '<done> <cancel>' '<all>' "$@"
}
