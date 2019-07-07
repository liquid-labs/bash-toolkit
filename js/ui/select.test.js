/* global test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILE_EXEC = 'eval "$(./dist/rollup-bash.sh src/ui/select.func.sh -)"'

test(`'selectOneCancel'-> cancel results in empty RESULT`, () => {
  const result = shell.exec(`${COMPILE_EXEC} && (OPTIONS="option a"$'\\n'"option b"; echo 1 | selectOneCancel RESULT OPTIONS 2>/dev/null; echo -n "$RESULT")`, execOpts)
  const expectedOut = expect.stringMatching(/^$/)
  assertMatchNoError(result, expectedOut)
})

test.each`
choice | selection
${`2`} | ${'option a'}
${`3`} | ${'option b'}
`(`'selectOneCancel'-> $choice should set RESULT to selection`, ({choice, selection}) => {
  // TODO: each-ify this test
  const OPTIONS = `OPTIONS="option a"$'\n'"option b"`
  const TEST_FUNC = `foo() { local RESULT; selectOneCancel RESULT OPTIONS 2>/dev/null; echo -n $RESULT; }`
  const test = (script) => `${COMPILE_EXEC} && (${OPTIONS}; ${TEST_FUNC}; echo ${script} | foo)`
  const result = shell.exec(test(choice), execOpts)
  const expectedOut = expect.stringMatching(selection)
  assertMatchNoError(result, expectedOut)
})
