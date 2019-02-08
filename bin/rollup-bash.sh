#!/usr/bin/env bash

# bash strict settings
set -o errexit # exit on errors
set -o nounset # exit on use of uninitialized variable
set -o pipefail

MAIN_FILE="${1}"; shift
OUT_FILE="${1}"; shift
SEARCH_DIRS="$@"

if [[ "${BASH_SOURCE[0]}" != "${MAIN_FILE}" ]]; then
  STD_DIR="$(npm explore @liquid-labs/bash-toolkit -- pwd)/src"
  if [[ -n "${SEARCH_DIRS}" ]]; then
    SEARCH_DIRS="${SEARCH_DIRS} $STD_DIR"
  else
    SEARCH_DIRS="$STD_DIR"
  fi
else # We are building ourselves, so we shim our functions.
  function echoerrandexit() {
    echo -e "${1}" >&2
    exit ${2:-1}
  }
fi

if ! which -s perl; then
  echoerrandexit "Perl is required."
  exit 10
fi

SCRIPT=$(cat <<'EOF'
use strict;
use warnings;

my $input_file=shift;
my $output_file=shift;
my @search_dirs=@ARGV;
my $find_search=join(' ', map("'$_'", @search_dirs));
open(my $input, '<:encoding(UTF-8)', $input_file)
  or die "Could not open file '$input_file'";
open(my $output, '>:encoding(UTF-8)', $output_file)
  or die "Could not open file '$output_file'";

while (<$input>) {
  if (/^\s*import (.+)/) {
    my $pattern=$1;
    # In an earlier version, had tried to use '-not -name', but the need to use
    # parents to group the tests seemed to cause problems with running the
    # embedded script.
    my $source_name=`find $find_search -name "$pattern*" -o -path "*$pattern*" | grep -v "\.test\." | grep -v "\.seqtest\."`;
    my $source_count = split(/\n/, $source_name);
    if ($source_count > 1) {
      print STDERR "Ambiguous results trying to import '$1' in '$input_file' @ line $. ";
      die 10;
    }
    elsif ($source_count == 0) {
      print STDERR "No source found trying to import '$1' in '$input_file' @ line $. ";
      die 10;
    }
    else {
      chomp($source_name);
      open(my $source, '<:encoding(UTF-8)', $source_name)
        or die "Could not open source file '$source_name' for import in '$input_file' @ line $.";
      while (my $pattern_line = <$source>) {
        print $output $pattern_line;
      }
    }
  }
  else {
    print $output $_;
  }
}
EOF
)

perl -e "$SCRIPT" "${MAIN_FILE}" "${OUT_FILE}" $SEARCH_DIRS

if [[ $(head -n 1 "$MAIN_FILE") == "#!"* ]]; then
  chmod a+x "${OUT_FILE}"
fi
