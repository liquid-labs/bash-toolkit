/* global expect */
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true
}

const assertNoError = (result) => {
  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)
}

const assertMatchNoError = (result, expectedOut) => {
  assertNoError(result)
  expect(result.stdout).toEqual(expectedOut)
}

export {
  assertMatchNoError,
  assertNoError,
  execOpts,
  shell
}
