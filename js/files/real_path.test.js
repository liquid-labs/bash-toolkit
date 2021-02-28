/* global test, expect, beforeAll, afterAll */
import { assertMatchNoError, shell, execOpts } from '../testlib'

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

const realFile = `/tmp/foo/real_dir/real_file`
const realDir = expect.stringMatching(new RegExp(`/tmp/foo/real_dir\\s*$`))

const verifyLink = (linkPath, expectedOut) => {
  const result =
    shell.exec(`source dist/files/real_path.func.sh && real_path ${linkPath}`, execOpts)

  assertMatchNoError(result, expectedOut)
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

test('real_path should resolve non-links to themselves', () => {
  verifyLink('/tmp/foo/real_dir', realDir)
  verifyLink('/tmp/foo/real_dir/real_file', realFile)
})

test('real_path should trim trailng dir-slash', () => {
  verifyLink('/tmp/foo/real_dir/', realDir)
  verifyLink('/tmp/foo/link_dir/', realDir)
})

test('real_path should not change the working directory', () => {
  const startDir = shell.pwd() + '' // .pwd() is returning an object...
  const result =
    shell.exec(`source dist/files/real_path.func.sh && real_path /tmp/foo/real_dir2/link_file_rel >/dev/null && echo -n "$PWD"`, execOpts)

  expect(result.stderr).toEqual('')
  expect(result.code).toBe(0)

  // the working directory itself may involve symlinks, so we have to analyze it; shell.pwd() will give the 'real' dir,
  // but bash $PWD gives the logical dir
  const pwdReal = shell.exec(`source dist/files/real_path.func.sh && real_path "${result.stdout}"`, execOpts).stdout
  expect(pwdReal).toEqual(pwdReal)
})
