function real_path {
  local FILE="${1:-}"
  if [[ -z "$FILE" ]]; then
    echo "'real_path' requires target file specified." >&2
    return 1
  elif [[ ! -e "$FILE" ]]; then
    echo "Target file '$FILE' does not exist." >&2
    return 1
  fi

  if [[ -h "$FILE" ]]; then
    function resolve_link {
      local POSSIBLE_REL_LINK="${1:-}"
      local APPEND="${2:-}"
      if [[ "$POSSIBLE_REL_LINK" == /* ]]; then
        echo "$POSSIBLE_REL_LINK${APPEND}"
      else
        # now we go into the dir containg the link and then navigate the possibly
        # relative link to the real dir
        cd "$START_DIR"
        cd "$(dirname "$FILE")"
        cd "$POSSIBLE_REL_LINK"
        echo "${PWD}${APPEND}"
        cd "$START_DIR"
      fi
    }

    # local START_DIR="$PWD"
    if [[ ! -d "$FILE" ]]; then
      # we need to get the real path to the real file
      local REAL_FILE_LINK_PATH="$(readlink "$FILE")"
      resolve_link "$(dirname "$REAL_FILE_LINK_PATH")" "/$(basename "$REAL_FILE_LINK_PATH")"
    else
      # we need to get the real path of the linked directory
      resolve_link "$(readlink "$FILE")"
    fi
  else
    echo "$FILE"
  fi
}
