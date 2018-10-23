/* global test, expect, jest */
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true,
}

test('will find npm-local executables', () => {
  // supresses err echo from shelljs
  console.error = jest.fn() // eslint-disable-line no-console
  const result = shell.exec(`source src/files/find-exec.func.sh && find-exec eslint "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/eslint\s*$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})

test('will find global executables', () => {
  // supresses err echo from shelljs
  console.error = jest.fn() // eslint-disable-line no-console
  let result = shell.exec(`source src/files/find-exec.func.sh && find-exec bash "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/bash\s*$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)

  result = shell.exec(`source src/files/find-exec.func.sh && find-exec bash`, execOpts)
  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})
