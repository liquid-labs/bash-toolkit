import echoerr

# Tries to find the named exec via NPM or optional search locations. The locations may either be paths or NPM packages.
function find_exec {
  local EXEC_NAME="$1"; shift

  # first, we look if it's in our own bin
  local EXEC="$(npm bin)/$EXEC_NAME"
  # next, we check other named package directories (if any)
  if [[ ! -x "$EXEC" ]]; then
    local SEARCH_REF
    for SEARCH_REF in "$@"; do
      if [[ "${SEARCH_REF}" == '@'* ]]; then # assume it's a package name
        EXEC="$(npm explore "${SEARCH_REF}" -- "npm bin")/${EXEC_NAME}"
        if [[ -x "$EXEC" ]]; then
          echo "${EXEC}"
          return 0
        fi
      else
        (
          cd "$SEARCH_REF"
          if [[ -x "$EXEC_NAME" ]]; then # try looking in the dir itself
            echo "${EXEC_NAME}"
            return 0
          else # see if it's an NPM thing...
            EXEC=$(npm bin)/$EXEC_NAME #
            if [[ -x "$EXEC" ]]; then
              echo "${EXEC}"
              return 0
            fi
          fi
        )
      fi
    done
  fi
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
    EXIT_CODE=10 echoerrandexit "Could not locate executable '$EXEC_NAME'; bailing out."
  fi
}
