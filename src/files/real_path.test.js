/* global test, expect, jest, beforeAll */
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true,
}

beforeAll(() => {
  // setup real dirs and file
  ['/tmp/foo', '/tmp/foo/real_dir', '/tmp/foo/real_dir2']
    .forEach((dir) => shell.mkdir(dir))
  shell.exec('touch /tmp/foo/real_dir/real_file')
  // setup links
  shell.exec('ln -s /tmp/foo/real_dir /tmp/foo/link_dir')
  shell.exec('ln -s /tmp/foo/real_dir/real_file /tmp/foo/link_dir/link_file_abs')
  shell.exec('cd /tmp/foo/link_dir && ln -s ../real_dir/real_file link_file_rel')
  shell.exec('ln -s /tmp/foo/real_dir/real_file /tmp/foo/real_dir2/link_file_abs')
  shell.exec('cd /tmp/foo/real_dir2 && ln -s ../real_dir/real_file link_file_rel')
})

afterAll(() => {
  shell.exec('rm -rf /tmp/foo')
})

const verifyLink = (linkPath, realPath) => {
  const result =
    shell.exec(`source src/files/real_path.func.sh && real_path ${linkPath}`, execOpts)
  const expectedOut =
    expect.stringMatching(new RegExp(`${realPath}\\s*$`))

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
}

test('real_path should resolve absolute file links', () => {
  verifyLink('/tmp/foo/real_dir2/link_file_abs', '/tmp/foo/real_dir/real_file')
  verifyLink('/tmp/foo/link_dir/link_file_abs', '/tmp/foo/real_dir/real_file')
})

test('real_path should resolve relative file links', () => {
  verifyLink('/tmp/foo/real_dir2/link_file_rel', '/tmp/foo/real_dir/real_file')
  verifyLink('/tmp/foo/link_dir/link_file_rel', '/tmp/foo/real_dir/real_file')
})
