/* global test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

test('rollup-bash will inline basic source', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/source_basic.sh ./test-tmp/source_basic.sh`, execOpts)
  const result = shell.exec('./test-tmp/source_basic.sh', execOpts)
  const expectedOut = expect.stringMatching(/^true[\s\n]*$/)
  assertMatchNoError(result, expectedOut)
})

test('rollup-bash will inline nested source', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/source_nested.sh ./test-tmp/source_nested.sh`, execOpts)
  const result = shell.exec('./test-tmp/source_nested.sh', execOpts)
  const expectedOut = expect.stringMatching(/^true\n$/)
  assertMatchNoError(result, expectedOut)
})

test('rollup-bash will import standard functions', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/import_basic.sh ./test-tmp/import_basic.sh`, execOpts)
  const result = shell.exec('./test-tmp/import_basic.sh', execOpts)
  const expectedOut = expect.stringMatching(/^a\na b\n$/)
  assertMatchNoError(result, expectedOut)
})

test('rollup-bash will only include a file once', () => {
  shell.exec(`./dist/rollup-bash.sh ./data/files/test/multi_include.sh ./test-tmp/multi_include.sh`, execOpts)
  const result = shell.exec('./test-tmp/multi_include.sh', execOpts)
  // The script output will test wether the 'echo true' got included only once from source.
  const expectedOut = expect.stringMatching(/^true\n$/)
  assertMatchNoError(result, expectedOut)
  // Now we grep the file to verify that the import only got imported once.
  assertMatchNoError(
    shell.exec(`grep 'list-add-item()' ./test-tmp/multi_include.sh | wc -l`),
    expect.stringMatching(/^\s*1[\s\n]*$/)
  )
})
