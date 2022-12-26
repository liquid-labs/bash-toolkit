/* global test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILE_EXEC = 'source dist/ui/select.func.pkg.sh'
const STRICT = ':' // TODO: setting any of the strict stuff here fails. Best guess is because the tests are non-interactie so things are not getting setup as select expects and it causes errors. We would like some better assurance that all this works in strict scripts, though.

test('\'selectOneCancel\'-> cancel results in empty RESULT', () => {
  const result = shell.exec(`${COMPILE_EXEC} && (OPTIONS="option a"$'\\n'"option b"; echo 1 | selectOneCancel RESULT OPTIONS 2>/dev/null; echo -n "$RESULT")`, execOpts)
  const expectedOut = expect.stringMatching(/^$/)
  assertMatchNoError(result, expectedOut)
})

const OPTIONS = 'OPTIONS="option a"$\'\\n\'"option b"'
// Select prints options to STDERR so the redirect is hiding the prompt questions.
const testFunc = (funcName) =>
  `foo() { local RESULT; ${funcName} RESULT OPTIONS 2>/dev/null; echo -n $RESULT; }`
const testString = (funcName, script) => `${STRICT}; ${COMPILE_EXEC} && (${OPTIONS}; ${testFunc(funcName)}; echo "${script}" | foo)`

test.each`
funcName             | choice | selection
${'selectOneCancel'} | ${'2'} | ${'option a'}
${'selectOneCancel'} | ${'3'} | ${'option b'}
${'selectOneCancelDefault'} | ${'2'} | ${'option a'}
${'selectOneCancelDefault'} | ${'3'} | ${'option b'}
${'selectOneCancelOther'} | ${'2'} | ${'option a'}
${'selectOneCancelOther'} | ${'3'} | ${'option b'}
${'selectOneCancelNew'} | ${'2'} | ${'option a'}
`('one-choice \'$funcName\'-> $choice should set RESULT to selection', ({ funcName, choice, selection }) => {
  const result = shell.exec(testString(funcName, choice), execOpts)
  const expectedOut = expect.stringMatching(selection)
  assertMatchNoError(result, expectedOut)
})

test.each`
funcName             | choice | selection
${'selectDoneCancel'} | ${'3'} | ${'option a'}
${'selectDoneCancel'} | ${'4'} | ${'option b'}
${'selectDoneCancelOther'} | ${'3'} | ${'option a'}
${'selectDoneCancelOther'} | ${'4'} | ${'option b'}
${'selectDoneCancelNew'} | ${'3'} | ${'option a'}
${'selectDoneCancelNew'} | ${'4'} | ${'option b'}
${'selectDoneCancelAllOther'} | ${'3'} | ${'option a'}
${'selectDoneCancelAllOther'} | ${'4'} | ${'option b'}
${'selectDoneCancelAllNew'} | ${'3'} | ${'option a'}
${'selectDoneCancelAllNew'} | ${'4'} | ${'option b'}
${'selectDoneCancelAnyOther'} | ${'3'} | ${'option a'}
${'selectDoneCancelAnyOther'} | ${'4'} | ${'option b'}
${'selectDoneCancelAnyNew'} | ${'3'} | ${'option a'}
${'selectDoneCancelAnyNew'} | ${'4'} | ${'option b'}
${'selectDoneCancelOtherDefault'} | ${'3'} | ${'option a'}
${'selectDoneCancelOtherDefault'} | ${'4'} | ${'option b'}
${'selectDoneCancelNewDefault'} | ${'3'} | ${'option a'}
${'selectDoneCancelNewDefault'} | ${'4'} | ${'option b'}
${'selectDoneCancelAll'} | ${'3'} | ${'option a'}
${'selectDoneCancelAll'} | ${'4'} | ${'option b'}
`('multi-choice \'$funcName\'-> $choice -> \'done\' should set RESULT to selection', ({ funcName, choice, selection }) => {
  const result = shell.exec(testString(funcName, `${choice}\n1`), execOpts)
  const expectedOut = expect.stringMatching(selection)
  assertMatchNoError(result, expectedOut)
})
