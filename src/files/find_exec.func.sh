import echoerr

function find_exec {
  local EXEC_NAME="$1"; shift

  # first, we look if it's in our own bin
  local EXEC="$(npm bin)/$EXEC_NAME"
  # next, we check other named package directories (if any)
  if [[ ! -x "$EXEC" ]]; then
    local SEARCH_PACKAGE
    for SEARCH_PACKAGE in "$@"; do
      pushd "$SEARCH_PACKAGE" > /dev/null
      EXEC=$(npm bin)/$EXEC_NAME
      if [[ -x "$EXEC" ]]; then break; fi
      popd > /dev/null
    done
  fi
  # next, we try global npm
  [[ -x "$EXEC" ]] || EXEC=$(npm bin -g)/$EXEC_NAME
  # finally, we look in the system PATH
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
    echoerrandexit "Could not locate executable '$EXEC_NAME'; bailing out."
  fi
}
