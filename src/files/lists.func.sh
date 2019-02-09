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
