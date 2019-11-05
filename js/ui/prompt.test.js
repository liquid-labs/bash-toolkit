/* global test describe expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILE_EXEC = 'eval "$(./dist/rollup-bash.sh src/ui/prompt.func.sh -)"'

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
})
