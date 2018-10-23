#/usr/bin/env bash
set -e

if ! which -s perl; then
  echo "$(basename ${BASH_SOURCE[0]}) requires perl be installed." >&2
  exit 10
fi
if [[ -h "${BASH_SOURCE[0]}" ]]; then
  MY_REAL_ROOT=$(dirname $(dirname $(readlink "${BASH_SOURCE[0]}")))
else
  MY_REAL_ROOT=$(dirname $(dirname "${BASH_SOURCE[0]}"))
fi

SCRIPT=$(cat <<'EOF'
use strict;
use warnings;

my $input_file=$ARGV[0];
my $output_file=$ARGV[1];
my $search_root=$ARGV[2];
open(my $input, '<:encoding(UTF-8)', $input_file)
  or die "Could not open file '$input_file'";
open(my $output, '>:encoding(UTF-8)', $output_file)
  or die "Could not open file '$output_file'";

while (<$input>) {
  if (/^\s*import (.+)/) {
    my $pattern=$1;
    my $source_name=`find "$search_root" -name "$pattern*" -o -path "*$pattern*"`;
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

cd $(npm root)/..
for i in `find src -name "*.sh"`; do
  o=dist/${i:4}
  mkdir -p "$(dirname $o)"
  perl -e "$SCRIPT" "$i" "$o" "$MY_REAL_ROOT"
done
