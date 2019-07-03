list-add-item() {
  local LIST_VAR="${1}"
  local ITEM="${2}"
  local SEP="${3:- }"

  if [[ -n "$ITEM" ]]; then
    if [[ -z "${!LIST_VAR:-}" ]]; then
      eval $LIST_VAR='"$ITEM"'
    else
      eval $LIST_VAR='"$(echo -e "${!LIST_VAR}${SEP}${ITEM}")"'
    fi
  fi
}

list-get-index() {
  local LIST_VAR="${1}"
  local TEST="${2}"
  local SEP="${3:- }"

  local ITEMS ITEM
  local INDEX=0
  while IFS="$SEP" read -ra ITEMS; do
    # the newline handling isn't strictly necessary, but makes things more
    # clear?
    if [[ "$SEP" == $'\n' ]]; then # see note in 'list-get-item' re. $'\n'
      if [[ "${ITEMS[0]}" == "$TEST" ]]; then
        echo $INDEX
        return
      fi
      INDEX=$(($INDEX + 1))
    else
      for ITEM in "${ITEMS[@]}"; do
        if [[ "$ITEM" == "$TEST" ]]; then
          echo $INDEX
          return
        fi
        INDEX=$(($INDEX + 1))
      done
    fi
  done <<< "$(echo -en "${!LIST_VAR}")"
}

list-get-item() {
  local LIST_VAR="${1}"
  local INDEX="${2}"
  local SEP="${3:- }"

  local CURR_INDEX=0
  local ITEMS
  while IFS="$SEP" read -ra ITEMS; do
    # The $'\n' construct to test for newline is not necessary (as of testing
    # 2019-06-03) not when sourcing the file and executing from the command
    # line. But it is necessary for the test to pass. No idea what's happening.
    # If someone figures it out, please note.
    if [[ "$SEP" == $'\n' ]]; then
      if (( $CURR_INDEX == $INDEX )) ; then
        echo "${ITEMS[0]}"
        return
      fi
      CURR_INDEX=$(($CURR_INDEX + 1))
    else
      echo "${ITEMS[$INDEX]}"
    fi
  done <<< "$(echo -en "${!LIST_VAR}")"
}
