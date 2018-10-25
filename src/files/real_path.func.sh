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
    # local START_DIR="$PWD"
    if [[ ! -d "$FILE" ]]; then
      # we need to get the real path to the real file
      local START_DIR="$PWD"
      local REAL_FILE_LINK_PATH="$(readlink "$FILE")"
      local POSSIBLE_REL_LINK="$(dirname "$REAL_FILE_LINK_PATH")"
      # now we go into the dir containg the link and then navigate the possibly
      # relative link to the real dir
      cd "$(dirname "$FILE")"
      cd "$POSSIBLE_REL_LINK"
      echo "$PWD/$(basename "$REAL_FILE_LINK_PATH")"
      cd "$START_DIR"
    else
      # we need to get the real path of the linked directory
      local POSSIBLE_REL_LINK="$(readlink "$FILE")"
      if [[ "$POSSIBLE_REL_LINK" == /* ]]; then
        echo "$POSSIBLE_REL_LINK"
      else
        cd "$(dirname "$FILE")"
        cd "$POSSIBLE_REL_LINK"
        echo "$PWD"
        cd "$START_DIR"
      fi
    fi
  else
    echo "$FILE"
  fi
}
