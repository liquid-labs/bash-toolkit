#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

MAIN_FILE="${1}"; shift
OUT_FILE="${1}"; shift
SEARCH_DIRS="$@"

if [[ "${BASH_SOURCE[0]}" == "${MAIN_FILE}" ]]; then
  # We are building ourselves and we need to shim our functions.
  echoerrandexit() {
    local red=`tput setaf 1`
    local reset=`tput sgr0`
    echo -e "${red}$*${reset}" | fold -sw 82 >&2
    exit ${2:-}
  }
else
  # If we see the '.sh' but are not our own target, then it's a test situation.
  STD_DIR="${PWD}/src"
  # So, if no '.sh', then we look for the STD_DIR in node_modules.
  if [[ "${BASH_SOURCE[0]}" != *'.sh' ]]; then
    STD_DIR="$(npm explore @liquid-labs/bash-toolkit -- pwd)/src"
  fi

  if [[ -n "${SEARCH_DIRS}" ]]; then
    SEARCH_DIRS="${SEARCH_DIRS} $STD_DIR"
  else
    SEARCH_DIRS="$STD_DIR"
  fi

# http://linuxcommand.org/lc3_adv_tput.php
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
purple=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`

bold=`tput bold`
red_b="${red}${bold}"
green_b="${green}${bold}"
yellow_b="${yellow}${bold}"
blue_b="${blue}${bold}"
purple_b="${purple}${bold}"
cyan_b="${cyan}${bold}"
white_b="${white}${bold}"

underline=`tput smul`
red_u="${red}${underline}"
green_u="${green}${underline}"
yellow_u="${yellow}${underline}"
blue_u="${blue}${underline}"
purple_u="${purple}${underline}"
cyan_u="${cyan}${underline}"
white_u="${white}${underline}"

red_bu="${red}${bold}${underline}"
green_bu="${green}${bold}${underline}"
yellow_bu="${yellow}${bold}${underline}"
blue_bu="${blue}${bold}${underline}"
purple_bu="${purple}${bold}${underline}"
cyan_bu="${cyan}${bold}${underline}"
white_bu="${white}${bold}${underline}"

reset=`tput sgr0`
if [[ $(uname) == 'Darwin' ]]; then
  GNU_GETOPT="$(brew --prefix gnu-getopt)/bin/getopt"
else
  GNU_GETOPT="$(which getopt)"
fi

# Usage:
#   eval "$(setSimpleOptions SHORT LONG= SPECIFY_SHORT:X LONG_SPEC:S= -- "$@")" \
#     || ( contextHelp; echoerrandexit "Bad options."; )
#
# Note the use of the intermediate TMP is important to preserve the exit value
# setSimpleOptions. E.g., doing 'eval "$(setSimpleOptions ...)"' will work fine,
# but because the last statement is the eval of the results, and not the function
# call itself, the return of setSimpleOptions gets lost.
#
# Instead, it's generally recommended to be strict, 'set -e', and use the TMP-form.
setSimpleOptions() {
  local VAR_SPEC LOCAL_DECLS
  local LONG_OPTS=""
  local SHORT_OPTS=""
  # Bash Bug? This looks like a straight up bug in bash, but the left-paren in
  # '--)' was matching the '$(' and causing a syntax error. So we use ']' and
  # replace it later.
  local CASE_HANDLER=$(cat <<EOF
    --]
      break;;
EOF
)
  while true; do
    if (( $# == 0 )); then
      echoerrandexit "setSimpleOptions: No argument to process; did you forget to include the '--' marker?"
    fi
    VAR_SPEC="$1"; shift
    local VAR_NAME LOWER_NAME SHORT_OPT LONG_OPT
    if [[ "$VAR_SPEC" == '--' ]]; then
      break
    elif [[ "$VAR_SPEC" == *':'* ]]; then
      VAR_NAME=$(echo "$VAR_SPEC" | cut -d: -f1)
      SHORT_OPT=$(echo "$VAR_SPEC" | cut -d: -f2)
    else # each input is a variable name
      VAR_NAME="$VAR_SPEC"
      SHORT_OPT=$(echo "${VAR_NAME::1}" | tr '[:upper:]' '[:lower:]')
    fi
    local OPT_ARG=$(echo "$VAR_NAME" | sed -Ee 's/[^=]//g' | tr '=' ':')
    VAR_NAME=$(echo "$VAR_NAME" | tr -d "=")
    LOWER_NAME=$(echo "$VAR_NAME" | tr '[:upper:]' '[:lower:]')
    LONG_OPT="$(echo "${LOWER_NAME}" | tr '_' '-')"

    if [[ -n "${SHORT_OPT}" ]]; then
      SHORT_OPTS="${SHORT_OPTS:-}${SHORT_OPT}${OPT_ARG}"
    fi

    LONG_OPTS=$( ( test ${#LONG_OPTS} -gt 0 && echo -n "${LONG_OPTS},") || true && echo -n "${LONG_OPT}${OPT_ARG}")

    LOCAL_DECLS="${LOCAL_DECLS:-}local ${VAR_NAME}='';"
    local VAR_SETTER="${VAR_NAME}=true;"
    if [[ -n "$OPT_ARG" ]]; then
      LOCAL_DECLS="${LOCAL_DECLS}local ${VAR_NAME}_SET='';"
      VAR_SETTER=${VAR_NAME}'="${2}"; '${VAR_NAME}'_SET=true; shift;'
    fi
    local CASE_SELECT="-${SHORT_OPT}|--${LONG_OPT}]"
    if [[ -z "$SHORT_OPT" ]]; then
      CASE_SELECT="--${LONG_OPT}]"
    fi
    CASE_HANDLER=$(cat <<EOF
    ${CASE_HANDLER}
      ${CASE_SELECT}
        $VAR_SETTER
        _OPTS_COUNT=\$(( \$_OPTS_COUNT + 1));;
EOF
)
  done # main while loop
  CASE_HANDLER=$(cat <<EOF
    case "\$1" in
      $CASE_HANDLER
    esac
EOF
)
  # replace the ']'; see 'Bash Bug?' above
  CASE_HANDLER=$(echo "$CASE_HANDLER" | perl -pe 's/\]$/)/')

  echo "$LOCAL_DECLS"

  cat <<EOF
local TMP # see https://unix.stackexchange.com/a/88338/84520
TMP=\$(${GNU_GETOPT} -o "${SHORT_OPTS}" -l "${LONG_OPTS}" -- "\$@") \
  || exit \$?
eval set -- "\$TMP"
local _OPTS_COUNT=0
while true; do
  $CASE_HANDLER
  shift
done
shift
EOF
#  echo 'if [[ -z "$1" ]]; then shift; fi' # TODO: explain this
}

echoerr() {
  local TMP
  TMP=$(setSimpleOptions NO_FOLD:F -- "$@")
  eval "$TMP"

  if [[ -z "$NO_FOLD" ]]; then
    echo -e "${red}$*${reset}" | fold -sw 82 >&2
  else
    echo -e "${red}$*${reset}"
  fi
}

echowarn() {
  local TMP
  TMP=$(setSimpleOptions NO_FOLD:F -- "$@")
  eval "$TMP"

  if [[ -z "$NO_FOLD" ]]; then
    echo -e "${yellow}$*${reset}" | fold -sw 82 >&2
  else
    echo -e "${yellow}$*${reset}"
  fi
}

echoerrandexit() {
  local TMP
  TMP=$(setSimpleOptions NO_FOLD:F -- "$@") || $(echo "Bad options: $*"; exit -10)
  eval "$TMP"

  local MSG="$1"
  local EXIT_CODE="${2:-10}"
  # TODO: consider providing 'passopts' method which coordites with 'setSimpleOptions' to recreate option string
  if [[ -n "$NO_FOLD" ]]; then
    echoerr --no-fold "$MSG"
  else
    echoerr "$MSG"
  fi
  exit $EXIT_CODE
}
fi

if ! which -s perl; then
  echoerrandexit "Perl is required."
  exit 10
fi

# TODO: track file as they are included
SCRIPT=$(cat <<'EOF'
use strict;
use warnings;
use Term::ANSIColor;
use File::Spec;

my $main_file=shift;
my $output_file=shift;
my @search_dirs=@ARGV;

my $find_search=join(' ', map("'$_'", @search_dirs));

my $output;
if ("$output_file" eq "-") {
  $output = *STDOUT;
}
else {
  open($output, '>:encoding(UTF-8)', $output_file)
    or die "Could not open file '$output_file'";
}

my $sourced_files = {};

sub printErr {
  my $msg = shift;

  print STDERR color('red');
  print STDERR "$msg\n";
  print STDERR color('reset');
}

sub process_file {
  my $input_file = shift;
  my $input_abs = $input_file =~ m|^/| && $input_file || File::Spec->rel2abs($input_file);
  my $source_base=($input_file =~ m|^(.*)/| ? $1 : ""); # that's 'dirname'
  if ($sourced_files->{$input_abs}) {
    # TODO: if 'verbose'
    # print "Dropping additional inclusion of '$input_file'.\n";
    return;
  }
  $sourced_files->{$input_abs} = 1;

  open(my $input, '<:encoding(UTF-8)', $input_file)
    or die "Could not open file '$input_file'";

  while (<$input>) {
    # Tried to do the 'comment' check as a negative lookahead, but was tricky.
    if ($_ !~ /#.*import\s+/ && /(^|;|do +|then +)\s*import\s+([^;\s]+)/) {
      my $pattern=$2;
      # In an earlier version, had tried to use '-not -name', but the need to
      # use parens to group the tests seemed to cause problems with running the
      # embedded script.
      # TODO: but why do we want '*$pattern*'? The first match should be enough...
      my $source_name=`find $find_search -name "$pattern*" -o -path "*$pattern*" | grep -v "\.test\." | grep -v "\.seqtest\."`;
      my $source_count = split(/\n/, $source_name);
      if ($source_count > 1) {
        printErr "Ambiguous results trying to import '$1' in file $input_file".'@'."$.";
        die 10;
      }
      elsif ($source_count == 0) {
        printErr "No source found trying to import '$1' in file $input_file".'@'."$.";
        die 10;
      }
      else {
        chomp($source_name);
        process_file($source_name);
      }
    }
    elsif ($_ !~ /#.*source\s+/ && m:(^|;|do +|then +)\s*source\s+((\./)?([^;\s]+)):) {
      my $next_file="$source_base/$4";
      my $source_spec="$2";
      if ($next_file =~ /\$/) {
        print "Leaving dynamic source: '$source_spec' in $input_file".'@'."$.\n";
        print $output $_;
      }
      elsif (-f "$next_file") {
        process_file($next_file);
      }
      else {
        printErr "No source found trying to source '$source_spec' in file $input_file".'@'."$.";
        print $output $_;
      }
    }
    else {
      print $output $_;
    }
  }
}

process_file($main_file);

EOF
)

perl -e "$SCRIPT" "${MAIN_FILE}" "${OUT_FILE}" $SEARCH_DIRS

if [[ "${OUT_FILE}" != '-' ]]; then
  if [[ $(head -n 1 "$MAIN_FILE") == "#!"* ]]; then
    chmod a+x "${OUT_FILE}"
  fi

  $(bash -n "${OUT_FILE}") || echoerrandexit "The rollup-script has syntax errors. See output above."
fi
