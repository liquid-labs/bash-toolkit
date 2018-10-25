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
  // link dir to contain other link
  shell.exec('ln -s /tmp/foo/real_dir /tmp/foo/link_dir')
  // setup links
  // absolute file links
  shell.exec('ln -s /tmp/foo/real_dir/real_file /tmp/foo/link_dir/link_file_abs')
  shell.exec('ln -s /tmp/foo/real_dir/real_file /tmp/foo/real_dir2/link_file_abs')
  // rel file links
  shell.exec('cd /tmp/foo/link_dir && ln -s ../real_dir/real_file link_file_rel')
  shell.exec('cd /tmp/foo/real_dir2 && ln -s ../real_dir/real_file link_file_rel')
  // abs dir links
  shell.exec('ln -s /tmp/foo/real_dir /tmp/foo/real_dir2/link_dir_abs')
  shell.exec('ln -s /tmp/foo/real_dir /tmp/foo/link_dir/link_dir_abs')
  // rel dir links
  shell.exec('cd /tmp/foo/link_dir && ln -s ../real_dir link_dir_rel')
  shell.exec('cd /tmp/foo/real_dir2 && ln -s ../real_dir link_dir_rel')
})

afterAll(() => {
  shell.exec('rm -rf /tmp/foo')
})

const realFile = expect.stringMatching(new RegExp(`/tmp/foo/real_dir/real_file\\s*$`))
const realDir = expect.stringMatching(new RegExp(`/tmp/foo/real_dir\\s*$`))

const verifyLink = (linkPath, expectedOut) => {
  const result =
    shell.exec(`source src/files/real_path.func.sh && real_path ${linkPath}`, execOpts)

  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
}

test('real_path should resolve absolute file links', () => {
  verifyLink('/tmp/foo/real_dir2/link_file_abs', realFile)
  verifyLink('/tmp/foo/link_dir/link_file_abs', realFile)
})

test('real_path should resolve relative file links', () => {
  verifyLink('/tmp/foo/real_dir2/link_file_rel', realFile)
  verifyLink('/tmp/foo/link_dir/link_file_rel', realFile)
})

test('real_path should resolve absolute directoy links', () => {
  verifyLink('/tmp/foo/real_dir2/link_dir_abs', realDir)
  verifyLink('/tmp/foo/link_dir', realDir)
  verifyLink('/tmp/foo/link_dir/link_dir_abs', realDir)
})

test('real_path should resolve relative directoy links', () => {
  verifyLink('/tmp/foo/real_dir2/link_dir_rel', realDir)
  verifyLink('/tmp/foo/link_dir/link_dir_rel', realDir)
})
