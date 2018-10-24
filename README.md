== bash-toolkit

A collection of useful bash functions.

== Usage

=== For npm packages

    npm install @liquid-labs/bash-toolkit

Include the following in the `prepare` script (or, as we do, include `build` and
call from `prepare`; so long as it's in the process):

    $(npm bin)/catalyst-bash-import

=== Non-npm usage

The script doesn't currently support usage outside the npm ecosystem.

=== In your code

Now, in your bash script, include the line:

    import the-function-path

If the name alone is not ambiguous, you can use it, or just get in the habit of
including the folder hierarchy / scoped names; e.g.:

    import files/find-exec

The `bash-import` will inline the library function at that point.

*CAVEATS* The bash source code must currently be in [`src`](https://github.com/Liquid-Labs/bash-toolkit/issues/2).
