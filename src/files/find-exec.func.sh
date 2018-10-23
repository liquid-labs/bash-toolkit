function find-exec() {
  local EXEC_NAME="$1"
  local PACKAGE_ROOT="${2:-}"

  local EXEC=''
  # prefer the package-local exec, if available
  if [[ -n "$PACKAGE_ROOT" ]]; then
    pushd "$PACKAGE_ROOT" > /dev/null
    # Search for the exec locall, then globally.
    EXEC=$(npm bin)/$EXEC_NAME
    popd > /dev/null
  fi
  if [[ ! -x "$EXEC" ]]; then
    if which -s "$EXEC_NAME"; then
      EXEC="$EXEC_NAME"
    else
      return 10
    fi
  fi

  echo $EXEC
}

function require-exec() {
  local EXEC_NAME="$1"
  if ! find-exec "$@"; then
    echo "Could not locate executable '$EXEC_NAME'; bailing out." >&2
    exit 10
  fi
}
