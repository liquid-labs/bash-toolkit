/* global test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILE_EXEC = 'eval "$(./dist/rollup-bash.sh src/ui/select.func.sh -)"'

test(`'selectOneCancel'-> cancel results in empty RESULT`, () => {
  const result = shell.exec(`${COMPILE_EXEC} && (OPTIONS="option a"$'\\n'"option b"; echo 1 | selectOneCancel RESULT OPTIONS 2>/dev/null; echo -n "$RESULT")`, execOpts)
  const expectedOut = expect.stringMatching(/^$/)
  assertMatchNoError(result, expectedOut)
})

const OPTIONS = `OPTIONS="option a"$'\n'"option b"`
const testFunc = (funcName) => `foo() { local RESULT; ${funcName} RESULT OPTIONS 2>/dev/null; echo -n $RESULT; }`
const testString = (funcName, script) => `${COMPILE_EXEC} && (${OPTIONS}; ${testFunc(funcName)}; echo ${script} | foo)`

test.each`
funcName             | choice | selection
${`selectOneCancel`} | ${`2`} | ${'option a'}
${`selectOneCancel`} | ${`3`} | ${'option b'}
${`selectOneCancelDefault`} | ${`2`} | ${'option a'}
${`selectOneCancelDefault`} | ${`3`} | ${'option b'}
${`selectOneCancelOther`} | ${`2`} | ${'option a'}
${`selectOneCancelOther`} | ${`3`} | ${'option b'}
`(`'$funcName'-> $choice should set RESULT to selection`, ({funcName, choice, selection}) => {
  const result = shell.exec(testString(funcName, choice), execOpts)
  const expectedOut = expect.stringMatching(selection)
  assertMatchNoError(result, expectedOut)
})
