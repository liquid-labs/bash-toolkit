# bash strict settings
set -o errexit # exit on errors; set -e
set -o nounset # exit on use of uninitialized variable
set -o pipefail # exit if any part of a pipeline fails (rather than just on failure of final piece)
