/* global test, expect, jest */
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true,
}

test('rollup-bash will inline basic source', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/source_basic.sh ./test-tmp/source_basic.sh`, execOpts)
  const result = shell.exec('./test-tmp/source_basic.sh', execOpts)
  const expectedOut = expect.stringMatching(/^true[\s\n]*$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})

test('rollup-bash will inline nested source', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/source_nested.sh ./test-tmp/source_nested.sh`, execOpts)
  const result = shell.exec('./test-tmp/source_nested.sh', execOpts)
  const expectedOut = expect.stringMatching(/^true\n$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})

test('rollup-bash will import standard functions', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/import_basic.sh ./test-tmp/import_basic.sh`, execOpts)
  const result = shell.exec('./test-tmp/import_basic.sh', execOpts)
  const expectedOut = expect.stringMatching(/^a\na b\n$/)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})
