/* global test describe expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

const COMPILE_EXEC = 'source dist/ui/echofmt.func.pkg.sh'
const STRICT = 'set -o errexit; set -o nounset; set -o pipefail'

// TODO: We would like to make the output test more precise, but can't seem to find something that matches the color
// control characters. We tried both '[^ -~]' and '[^\x20-\x7E]' to cover 'non-printable' characters, but neither
// worked...

const checkQuiteEchos = (result) => {
  expect(result.stdout).toEqual('')
  expect(result.stderr).toEqual(expect.stringMatching(/^.*hi.*\n$/))
  expect(result.code).toBe(0)
}

describe('echofmt', () => {
  test('echo hi', () => {
    const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; echofmt hi`, execOpts)
    const expectedOut = expect.stringMatching(/^.*hi.*\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('echo "hi\nbye"', () => {
    const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; echofmt "hi\nbye"`, execOpts)
    const expectedOut = expect.stringMatching(/^.*hi\nbye.*\n$/)
    assertMatchNoError(result, expectedOut)
  })

  test('folds longer lines', () => {
    // 80 x a + ' abc' makes this 84 long and should trigger default fold
    let ax80 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
    const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; echofmt ${ax80} abc`, execOpts)
    const expectedOut = expect.stringMatching(new RegExp(`^.*${ax80} [\n]abc.*\n$`))
    assertMatchNoError(result, expectedOut)
  })

  describe('when ECHO_QUIET=true', () => {
    test('supresses regular messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_QUIET=true echofmt hi`, execOpts)
      assertMatchNoError(result, '')
    })

    test('supresses info messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_QUIET=true echofmt --info hi`, execOpts)
      assertMatchNoError(result, '')
    })

    test('echos warning messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_QUIET=true echofmt --warn hi`, execOpts)
      checkQuiteEchos(result)
    })

    test('echoes error messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_QUIET=true echofmt --error hi`, execOpts)
      checkQuiteEchos(result)
    })
  })

  describe('when ECHO_SILENT=true', () => {
    test('supresses regular messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_SILENT=true echofmt hi`, execOpts)
      assertMatchNoError(result, '')
    })

    test('supresses info messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_SILENT=true echofmt --info hi`, execOpts)
      assertMatchNoError(result, '')
    })

    test('supresses warning messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_SILENT=true echofmt --warn hi`, execOpts)
      assertMatchNoError(result, '')
    })

    test('echoes error messages', () => {
      const result = shell.exec(`${STRICT}; ${COMPILE_EXEC}; ECHO_SILENT=true echofmt --error hi`, execOpts)
      checkQuiteEchos(result)
    })
  })
})
