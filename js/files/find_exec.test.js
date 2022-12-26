/* global test, expect, jest */
import { assertMatchNoError, shell, execOpts } from '../testlib'

// TODO: run once and capture inresult
const COMPILED_EXEC = 'source dist/files/find_exec.func.pkg.sh'
const STRICT = 'set -o errexit; set -o nounset; set -o pipefail'

test('find_exec will find npm-local executables', () => {
  const result = shell.exec(`${STRICT}; ${COMPILED_EXEC} && find_exec eslint "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/eslint\s*$/)
  assertMatchNoError(result, expectedOut)
})

test('find_exec will search multiple NPM directories', () => {
  const result = shell.exec(`${STRICT}; ${COMPILED_EXEC} && find_exec eslint /tmp /etc "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/eslint\s*$/)
  assertMatchNoError(result, expectedOut)
})

test('find_exec will find global executables', () => {
  let result = shell.exec(`${STRICT}; ${COMPILED_EXEC} && find_exec bash "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/bash\s*$/)

  assertMatchNoError(result, expectedOut)

  result = shell.exec(`${STRICT}; ${COMPILED_EXEC} && find_exec bash`, execOpts)
  assertMatchNoError(result, expectedOut)
})

test('find_exec and require-exec will fail when no exec found', () => {
  // supresses err echo from shelljs
  console.error = jest.fn() // eslint-disable-line no-console
  let result = shell.exec(`${STRICT}; ${COMPILED_EXEC} && find_exec fizzyboo "$PWD"`, execOpts)
  const expectedErr = expect.stringContaining("Could not locate executable 'fizzyboo'")

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual('')
  expect(result.code).toBe(10)

  result = shell.exec(`${STRICT}; ${COMPILED_EXEC} && require-exec fizzyboo`, execOpts)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.stdout).toEqual('')
  expect(result.code).toBe(10)
})
