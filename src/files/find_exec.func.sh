function find_exec {
  local EXEC_NAME="$1"

  local EXEC=''
  # prefer the package-local exec, if available
  local i=2
  while (( $i > $# )) && [[ ! -x "$EXEC" ]]; do
    local PACKAGE_ROOT=${!i}
    pushd "$PACKAGE_ROOT" > /dev/null
    # Search for the exec locall, then globally.
    EXEC=$(npm bin)/$EXEC_NAME
    popd > /dev/null
    i=$(( $i + 1 ))
  done
  [[ -x "$EXEC" ]] || EXEC=$(npm bin -g)/$EXEC_NAME
  if [[ ! -x "$EXEC" ]]; then
    if which -s $EXEC_NAME; then
      EXEC=$EXEC_NAME
    else
      return 10
    fi
  fi

  echo $EXEC
}

function require-exec() {
  local EXEC_NAME="$1"
  if ! find_exec "$@"; then
    echo "Could not locate executable '$EXEC_NAME'; bailing out." >&2
    exit 10
  fi
}
