import { assertMatchNoError, shell, execOpts } from '../testlib'

const testFuncSimple2Opts = `set -e
source src/cli/options.func.sh
function f() {
  local TMP
  TMP=$(setSimpleOptions AOPT BOPT -- "$@")
  eval "$TMP"
  echo "AOPT: $AOPT"
  echo "BOPT: $BOPT"
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

  describe('short option renaming', () => {
    const testShortRename = `set -e
    source src/cli/options.func.sh
    function f() {
      local TMP
      TMP=$(setSimpleOptions AOPT:B -- "$@")
      eval "$TMP"
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
  })
})
