/* global test, expect, jest */
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true,
}

test('find-exec will find npm-local executables', () => {
  let result = shell.exec(`source src/files/find-exec.func.sh && find-exec eslint "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/eslint\s*$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})

test('find-exec will search multiple NPM directories', () => {
  const result = shell.exec(`source src/files/find-exec.func.sh && find-exec eslint /tmp /etc "$PWD"`, execOpts)
  const expectedOut = expect.stringMatching(/eslint\s*$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})

test('find-exec will find global executables', () => {
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

test('find-exec and require-exec will fail when no exec found', () =>{
  // supresses err echo from shelljs
  console.error = jest.fn() // eslint-disable-line no-console
  let result = shell.exec(`source src/files/find-exec.func.sh && find-exec fizzyboo "$PWD"`, execOpts)
  const expectedErr = expect.stringContaining("Could not locate executable 'fizzyboo'")

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual('')
  expect(result.code).toBe(10)

  result = shell.exec(`source src/files/find-exec.func.sh && require-exec fizzyboo`, execOpts)
  expect(result.stderr).toEqual(expectedErr)
  expect(result.stdout).toEqual('')
  expect(result.code).toBe(10)
})
