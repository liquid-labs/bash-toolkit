/* global describe, test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILED_EXEC = 'eval "$("$(npm bin)/bash-rollup" bash/cli/options.func.sh -)"'

const testFuncSimple2Opts = `set -e
${COMPILED_EXEC}
function f() {
  eval "$(setSimpleOptions AOPT BOPT -- "$@")"
  echo "AOPT: $AOPT"
  echo "BOPT: $BOPT"
}`

const testFuncPositionals = `set -e
${COMPILED_EXEC}

function f() {
  eval "$(setSimpleOptions AOPT BOPT -- "$@")"
  echo "1: $1"
  echo "2: $2"
}`

describe('setSimpleOptions', () => {
  test('will process a single short option based on lowercased first letter of option name', () => {
    const result = shell.exec(`${testFuncSimple2Opts}; f -a`, execOpts)
    const expectedOut = expect.stringMatching(/^AOPT: true\nBOPT: \n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('will process multiple short option', () => {
    const result = shell.exec(`${testFuncSimple2Opts}; f -a -b`, execOpts)
    const expectedOut = expect.stringMatching(/^AOPT: true\nBOPT: true\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('will process a single long option based on lowercase version of option naame', () => {
    const result = shell.exec(`${testFuncSimple2Opts}; f --aopt`, execOpts)
    const expectedOut = expect.stringMatching(/^AOPT: true\nBOPT: \n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('will process multiple long option', () => {
    const result = shell.exec(`${testFuncSimple2Opts}; f --aopt --bopt`, execOpts)
    const expectedOut = expect.stringMatching(/^AOPT: true\nBOPT: true\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('will process a single short and long option', () => {
    const result = shell.exec(`${testFuncSimple2Opts}; f -a --bopt`, execOpts)
    const expectedOut = expect.stringMatching(/^AOPT: true\nBOPT: true\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('will properly set quoted positional options', () => {
    const result = shell.exec(`${testFuncPositionals}; f "foo bar" baz`, execOpts)
    const expectedOut = expect.stringMatching(/^1: foo bar\n2: baz\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('will properly set quoted positional options with options', () => {
    const result = shell.exec(`${testFuncPositionals}; f -a "foo bar" baz`, execOpts)
    const expectedOut = expect.stringMatching(/^1: foo bar\n2: baz\n$/)
    assertMatchNoError(result, expectedOut)
  })

  describe('short option renaming', () => {
    const testShortRename = `set -e
    ${COMPILED_EXEC}
    function f() {
      eval "$(setSimpleOptions AOPT:B -- "$@")"
      echo "AOPT: $AOPT"
    }`

    const testShortSuppress = `${COMPILED_EXEC}
    function f() {
      eval "$(setSimpleOptions AOPT: -- "$@")"
      echo "AOPT: $AOPT"
    }`

    test('recognizes long form', () => {
      const result = shell.exec(`${testShortRename}; f --aopt`, execOpts)
      const expectedOut = expect.stringMatching(/^AOPT: true\n$/)
      assertMatchNoError(result, expectedOut)
    })

    test('recognizes renamed short form and does not force lower case', () => {
      const result = shell.exec(`${testShortRename}; f -B`, execOpts)
      const expectedOut = expect.stringMatching(/^AOPT: true\n$/)
      assertMatchNoError(result, expectedOut)
    })

    test('rejects default short form', () => {
      const result = shell.exec(`${testShortRename}; f -a`, execOpts)
      const expectedErr = expect.stringMatching(/getopt: invalid option -- a/)
      expect(result.stderr).toEqual(expectedErr)
      expect(result.stdout).toEqual('')
      expect(result.code).toBe(1)
    })

    test('suppresses short option when indicated', () => {
      const result = shell.exec(`${testShortSuppress}; f -a`, execOpts)
      const expectedErr = expect.stringMatching(/getopt: invalid option -- a/)
      expect(result.stderr).toEqual(expectedErr)
      expect(result.stdout).toEqual('')
      expect(result.code).toBe(1)
    })
  })

  describe('required value', () => {
    test(`sets incoming value with long form 'opt=foo'`, () => {
      const result = shell.exec(`set -e; ${COMPILED_EXEC}; f() { eval "$(setSimpleOptions OPT= -- "$@")"; echo "OPT: $OPT"; }; f --opt=foo`, execOpts)
      const expectedOut = expect.stringMatching(/^OPT: foo\n$/)
      assertMatchNoError(result, expectedOut)
    })

    test(`results in error when no required value provided`, () => {
      const result = shell.exec(`set -e; ${COMPILED_EXEC}; f() { eval "$(setSimpleOptions OPT= -- "$@")"; echo "OPT: $OPT"; }; f --opt`, execOpts)
      const expectedErr = expect.stringMatching(/requires an argument\s*$/)
      expect(result.stderr).toEqual(expectedErr)
      expect(result.stdout).toEqual('')
      expect(result.code).toBe(1)
    })

    test(`supports mixed required and value-less options`, () => {
      const result = shell.exec(`set -e; ${COMPILED_EXEC}; f() { eval "$(setSimpleOptions NOVAL OPT= -- "$@")"; echo "NOVAL: $NOVAL"; echo "OPT: $OPT"; }; f --noval; f --opt=foo; f --noval --opt=bar`, execOpts)
      const expectedOut = expect.stringMatching(/^NOVAL: true\nOPT: \nNOVAL: \nOPT: foo\nNOVAL: true\nOPT: bar\n$/)
      assertMatchNoError(result, expectedOut)
    })

    test.each(["'",']'])(`properly escapse special char: %s`, (c) => {
      const result = shell.exec(`set -e; ${COMPILED_EXEC}; f() { eval "$(setSimpleOptions OPT= -- "$@")"; echo "OPT: $OPT"; }; f --opt="foo${c}bar"`, execOpts)
      const expectedOut = expect.stringMatching(new RegExp(`^OPT: foo${c}bar\n`))// /^OPT: foo'bar\n$/)
      assertMatchNoError(result, expectedOut)
    })
  }) // describe('required value'...

  describe('passthru values', () => {
    test.each([[`--opt`, `OPT^`, `--opt`],
      [`--opt foo`, `OPT^`, `--opt foo`],
      [`-o`, `OPT^`, `-o`],
      [`-Z`, `OPT:Z^`, `-Z`],
      [`--opt=foo`, `OPT=^`, `--opt foo`],
      [`-o foo`, `OPT=^`, `-o foo`],
      [`--opt foo`, `OPT=^`, `--opt foo`],
      [`--opt=foo --no-pass`, `OPT=^ NO_PASS`, `--opt foo`],
      [`-Z foo`, `OPT:Z=^`, `-Z foo`],
      [`--opt "foo bar"`, `OPT=^`, `--opt foo bar`],
      [`--opt "foo 'bar"`, `OPT=^`, `--opt foo 'bar`],
      [`--opt 'foo "bar'`, `OPT=^`, `--opt foo "bar`]])(
      `remain on the positional when using options %s`, (args, spec, out) => {
        const result = shell.exec(`set -e; ${COMPILED_EXEC}; function f() { eval "$(setSimpleOptions ${spec} -- "$@")"; echo "$@"; }; f ${args}`, execOpts)
        const expectedOut = expect.stringMatching(new RegExp(`^${out}\n$`))
        assertMatchNoError(result, expectedOut)
      })

    test.each([[`--opt "foo bar"`, `foo bar`],
      [`--opt "foo' bar"`, `foo' bar`]])(
      `will properly passthrough complex parameters`, (args, out) => {
        const result = shell.exec(`set -e; ${COMPILED_EXEC}; inner() { eval "$(setSimpleOptions OPT= -- "$@")"; echo "$OPT"; }; outer() { eval "$(setSimpleOptions OPT=^ -- "$@")"; inner "$@"; }; outer ${args}`, execOpts)
        const expectedOut = expect.stringMatching(new RegExp(`^${out}\n$`))
        assertMatchNoError(result, expectedOut)
      })
  })
})
