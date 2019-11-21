/* global test describe expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILE_EXEC = 'eval "$(./dist/rollup-bash.sh src/ui/prompt.func.sh -)"'

describe('get-answer', () => {
  test(`'--multi-line' supports multi-line input`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; unset FOO; get-answer --multi-line "prompt: " FOO <<< 'bar
baz
.'; echo "FOO: $FOO"`, execOpts)
    const expectedOut = expect.stringMatching(/FOO: bar\nbaz\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test(`'--multi-line' properly supports default`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; unset FOO; get-answer --multi-line "prompt: " FOO 'bar
baz' <<< ''; echo "FOO: $FOO"`, execOpts)
    const expectedOut = expect.stringMatching(/FOO: bar\nbaz\n$/)
    assertMatchNoError(result, expectedOut)
  })
})

describe('require-answer', () => {
  /* TODO: tried to optmize by compiling in 'beforeAll', but had challenges
  let compilation
  beforeAll(() => {
    let result = shell.exec(`./dist/rollup-bash.sh src/ui/prompt.func.sh -`, execOpts)
    compilation = result.stdout
  })*/

  /* TODO: nothing works here, tried:
  const result = shell.exec(`set -e; ${COMPILE_EXEC}; unset FOO; export -f require-answer; export -f setSimpleOptions; setSimpleOptions() { :; }; bash -c require-answer "prompt: " FOO &
PID=$!; sleep 0.1; kill $PID`, execOpts)
  => acts as if it's getting blank input and tries to call the 'echoerr' and failes

  const result = shell.exec(`set -e; ${COMPILE_EXEC}; timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }; unset FOO; export -f require-answer; export -f setSimpleOptions; setSimpleOptions() { :; }; timeout 1 bash -c require-answer "prompt: " FOO`, execOpts)
  => dies with '-o: command not found'

  test(`displays prompt`, () => {
    // No idea why, but leaving 'setSimpleOptions' as is causes the 'bash' call to exit with '-o: command not found'.
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }; unset FOO; export -f require-answer; export -f setSimpleOptions; setSimpleOptions() { :; }; bash -c require-answer "prompt: " FOO &
PID=$!; sleep 0.1; kill $PID`, execOpts)
    const expectedOut = expect.stringMatching(/^prompt: $/)
    assertMatchNoError(result, expectedOut)
  })*/

  test.each([
      [`foo`, `foo`],
      [`'foo bar'`, `foo bar`],
      [`'hey"mate'`, `hey"mate`],
      [`"hey'mate"`, `hey'mate`]])
    (`handles input: %s`, (input, output) => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; unset FOO; require-answer "prompt: " FOO <<< ${input}; echo "FOO: $FOO"`, execOpts)
    /* const result = shell.exec(`set -e; cat <<'EOFF' | eval
${compilation}
EOFF
unset FOO; require-answer "prompt: " FOO <<< ${input}; echo "FOO: $FOO"`, execOpts) */
    const expectedOut = expect.stringMatching(new RegExp(`^FOO: ${output}\n$`))
    assertMatchNoError(result, expectedOut)
  })

  test(`does not ask any questions when var already set`, () => {
    let result = shell.exec(`set -e; ${COMPILE_EXEC}; FOO=foo; require-answer "prompt: " FOO; echo "FOO: $FOO"`, execOpts)
    let expectedOut = expect.stringMatching(/^FOO: foo\n$/)
    assertMatchNoError(result, expectedOut)

    result = shell.exec(`set -e; ${COMPILE_EXEC}; FOO=foo; require-answer "prompt: " FOO <<< bar; echo "FOO: $FOO"`, execOpts)
    expectedOut = expect.stringMatching(/^FOO: foo\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test(`will ask for var even when present when forced`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; FOO=foo; require-answer --force "prompt: " FOO <<< bar; echo "FOO: $FOO"`, execOpts)
    const expectedOut = expect.stringMatching(/^FOO: bar\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test(`will set default to existing value when forced`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; FOO=foo; require-answer --force "prompt: " FOO <<< ''; echo "FOO: $FOO"`, execOpts)
    const expectedOut = expect.stringMatching(/^FOO: foo\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test(`will recognize override default when forced`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; FOO=foo; require-answer --force "prompt: " FOO BAR <<< ''; echo "FOO: $FOO"`, execOpts)
    const expectedOut = expect.stringMatching(/^FOO: BAR\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test(`'--multi-line' properly supports default`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; unset FOO; require-answer --multi-line "prompt: " FOO 'bar
baz' <<< ''; echo "FOO: $FOO"`, execOpts)
    const expectedOut = expect.stringMatching(/FOO: bar\nbaz\n$/)
    assertMatchNoError(result, expectedOut)
  })
})

describe('yes-no', () => {
  const didNotUnderstandMatch = expect.stringMatching(/^Did not understand.*/)
  test.each(['y', 'Y', 'yes', 'YES', 'yES', 'YeS'])(`is positive with for '%s'`, (input) => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no <<< '${input}'`, execOpts)
    const expectedOut = expect.stringMatching(/^$/)
    assertMatchNoError(result, expectedOut)
  })

  test.each(['n', 'N', 'no', 'NO', 'No', 'nO'])(`is negative with for '%s'`, (input) => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no <<< '${input}'`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual('')
    expect(result.code).toBe(1)
  })

  test.each(['yeah', 'nah', 'blah'])(`does not understand '%s' and accepts positive re-query`, (input) => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no <<< '${input}'$'\\n''y'`, execOpts)
    assertMatchNoError(result, didNotUnderstandMatch)
  })

  test.each(['yeah', 'nah', 'blah'])(`does not understand '%s' and accepts negative re-query`, (input) => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no <<< '${input}'$'\\n''n'`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual(didNotUnderstandMatch)
    expect(result.code).toBe(1)
  })

  /* TODO: the problem seems to be that 'read' knows it's not in an interactive shell and so
     supresses the prompt. I can't fix while on plane, so will deal with this later.
  test.only(`displays prompt as expected`, () => {
    const prompt=`This is the prompt: `
    const myOpts = Object.assign({}, execOpts)
    myOpts.timeout = 2000 // the input redirection kills stdout... so, this is a hack.
    myOpts.silent = false
    // const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no 'This is the prompt: '`, myOpts)
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no 'This is the prompt: ' <<< y`, execOpts)
    const expectedOut = expect.stringMatching(new RegExp(`^${prompt}$`))
    console.log(`stderr: ${result.stderr}`)
    console.log(`stdout: ${result.stdout}`)
    expect(result.stderr).toEqual(expectedOut) // the prompt is actually on stderr
    expect(result.stdout).toEqual('')
    expect(result.code).toBe(0)
  })*/

  test.each([['y', 0], ['n', 1]])(`default '%s' results in return code '%d'.`, (def, code) => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; yes-no '' '${def}' <<< ''`, execOpts)
    expect(result.stderr).toEqual('')
    expect(result.stdout).toEqual('')
    expect(result.code).toBe(code)
  })
})

describe(`gather-answers`, () => {
  test(`gathers named fields`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; FIELDS='F1 F2'; gather-answers "$FIELDS" <<< 'val1'$'\\n''val2'; echo $F1 $F2`, execOpts)
    const expectedOut = expect.stringMatching(/^val1 val2\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test(`skips defined fields`, () => {
    const result = shell.exec(`set -e; ${COMPILE_EXEC}; FIELDS='F1 F2'; F1='foo'; gather-answers "$FIELDS" <<< 'val1'$'\\n''val2'; echo $F1 $F2`, execOpts)
    const expectedOut = expect.stringMatching(/^foo val1\n$/)
    assertMatchNoError(result, expectedOut)
  })

  describe(`with '--verify'`, () => {
    test(`will reflect values and ask for verification`, () => {
      const result = shell.exec(`set -e; ${COMPILE_EXEC}; FIELDS='F1 F2'; gather-answers --verify "$FIELDS" <<< 'val1'$'\\n''val2'$'\\n''y'; echo $F1 $F2`, execOpts)
      // notice, we only look at the tail of the output
      const expectedOut = expect.stringMatching(/Verify the following:\nF1: val1\nF2: val2\s*\nval1 val2\n$/)
      assertMatchNoError(result, expectedOut)
    })

    test(`udpates fields on second loop when not verified`, () => {
      const result = shell.exec(`set -e; ${COMPILE_EXEC}; FIELDS='F1 F2'; gather-answers --verify "$FIELDS" <<< 'val1'$'\\n''val2'$'\\n''n'$'\\n''blah1'$'\\n''blah2'$'\\n'y; echo $F1 $F2`, execOpts)
      // notice, we only look at the tail of the output
      const expectedOut = expect.stringMatching(/blah1 blah2\n$/)
      assertMatchNoError(result, expectedOut)
    })
  })
})
