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
    echo "${1}" >&2
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
fi

if ! which -s perl; then
  echoerrandexit "Perl is required."
  exit 10
fi

# TODO: track file as they are included
SCRIPT=$(cat <<'EOF'
use strict;
use warnings;
use File::Spec;

my $main_file=shift;
my $output_file=shift;
my @search_dirs=@ARGV;

my $find_search=join(' ', map("'$_'", @search_dirs));

open(my $output, '>:encoding(UTF-8)', $output_file)
  or die "Could not open file '$output_file'";

my $sourced_files = {};

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
        print STDERR "Ambiguous results trying to import '$1' in '$input_file' @ line $.\n";
        die 10;
      }
      elsif ($source_count == 0) {
        print STDERR "No source found trying to import '$1' in '$input_file' @ line $.\n";
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
        print STDERR "No source found trying to source '$source_spec' in $input_file".'@'."$.\n";
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

# perl -e "$SCRIPT" "${MAIN_FILE}" "${OUT_FILE}" $SEARCH_DIRS
perl -e "$SCRIPT" "${MAIN_FILE}" "${OUT_FILE}" $SEARCH_DIRS

if [[ $(head -n 1 "$MAIN_FILE") == "#!"* ]]; then
  chmod a+x "${OUT_FILE}"
fi
