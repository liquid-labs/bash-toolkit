# http://linuxcommand.org/lc3_adv_tput.php
echo "FOO" #DEBUG
red=$(test -n "$TERM" && tput setaf 1)
green=$(test -n "$TERM" && tput setaf 2)
yellow=$(test -n "$TERM" && tput setaf 3)
blue=$(test -n "$TERM" && tput setaf 4)
purple=$(test -n "$TERM" && tput setaf 5)
cyan=$(test -n "$TERM" && tput setaf 6)
white=$(test -n "$TERM" && tput setaf 7)

bold=$(test -n "$TERM" && tput bold)
red_b="${red}${bold}"
green_b="${green}${bold}"
yellow_b="${yellow}${bold}"
blue_b="${blue}${bold}"
purple_b="${purple}${bold}"
cyan_b="${cyan}${bold}"
white_b="${white}${bold}"

underline=$(test -n "$TERM" && tput smul)
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

reset=$(test -n "$TERM" && tput sgr0)
echo "OOF" #DEBUG
