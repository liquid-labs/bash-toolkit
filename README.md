== bash-toolkit

A collection of useful bash functions.

== Usage

=== For npm packages

    npm install @liquid-labs/bash-toolkit

In the install process, copy the installed file to `lib` (by convention). This
can be added to the npm `prepare` script:

    "prepare": "rsync -r --delete --exclude='*.test.*' --exclude='*.seqtest.*' node_modules/@liquid-labs/bash-toolkit/src/ lib/"

Or where appropriate.
