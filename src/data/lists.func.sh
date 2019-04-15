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

  local ITEM
  local INDEX=0
  for ITEM in ${!LIST_VAR}; do
    if [[ "$ITEM" == "$TEST" ]]; then
      echo $INDEX
      return
    fi
    INDEX=$(($INDEX + 1))
  done

  echo ''
}

list-get-item() {
  local LIST_VAR="${1}"
  local INDEX="${2}"

  local LIST=(${!LIST_VAR})
  echo ${LIST[$INDEX]}
}
