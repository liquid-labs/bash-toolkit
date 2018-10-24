/* global test, expect, jest, beforeAll */
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true,
}

beforeAll(() => {
  shell.mkdir('/tmp/foo')
  shell.mkdir('/tmp/foo/real_dir', '/tmp/foo/real_dir2')
  shell.exec('touch /tmp/foo/real_dir/real_file')
  shell.exec('ln -s /tmp/foo/real_dir /tmp/foo/link_dir')
  shell.exec('ln -s /tmp/foo/real_dir/real_file /tmp/foo/link_dir/link_file_abs')
  shell.exec('cd /tmp/foo/link_dir && ln -s ../real_dir/real_file link_file_rel')
  shell.exec('ln -s /tmp/foo/real_dir/real_file /tmp/foo/real_dir2/link_file_abs')
  shell.exec('cd /tmp/foo/real_dir2 && ln -s ../real_dir/real_file link_file_rel')
})

afterAll(() => {
  shell.exec('rm -rf /tmp/foo')
})

test('real_path should resolve absolute file links', () => {
  let result = shell.exec(`source src/files/real_path.func.sh && real_path /tmp/foo/real_dir2/link_file_abs`, execOpts)
  const expectedOut = expect.stringMatching(new RegExp('/tmp/foo/real_dir/real_file\\s*$'))

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)

  result = shell.exec(`source src/files/real_path.func.sh && real_path /tmp/foo/link_dir/link_file_abs`, execOpts)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})

test('real_path should resolve relative file links', () => {
  let result = shell.exec(`source src/files/real_path.func.sh && real_path /tmp/foo/real_dir2/link_file_rel`, execOpts)
  const expectedOut = expect.stringMatching(new RegExp('/tmp/foo/real_dir/real_file\\s*$'))

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)

  result = shell.exec(`source src/files/real_path.func.sh && real_path /tmp/foo/link_dir/link_file_rel`, execOpts)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
})
