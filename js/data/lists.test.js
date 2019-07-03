/* global test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

test('list-add-item should append items', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=''; list-add-item LIST a; echo $LIST; list-add-item LIST b; echo $LIST`, execOpts)
  const expectedOut = expect.stringMatching(/^a\na b\n$/)
  assertMatchNoError(result, expectedOut)
})

test('list-add-item should handle spaces with newline seperator', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=''; list-add-item LIST 'a b' "\n"; echo -e "$LIST"; list-add-item LIST 'c d' "\n"; echo -en "$LIST"`, execOpts)
  const expectedOut = expect.stringMatching(/^a b\na b\nc d$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-index should echo index of item if present', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST='hey ho'; list-get-index LIST ho`, execOpts)
  const expectedOut = expect.stringMatching(/^1\n$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-index should echo "" if item not present', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST='heythere ho'; list-get-index LIST hey`, execOpts)
  const expectedOut = expect.stringMatching(/^$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-index should handle newline seperator', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=$(echo -en "hey\nho"); list-get-index LIST ho "\n"`, execOpts)
  const expectedOut = expect.stringMatching(/^1\n$/)
  assertMatchNoError(result, expectedOut)
})

test("list-get-index should handle ';' seperator", () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST="hey;ho"; list-get-index LIST ho ";"`, execOpts)
  const expectedOut = expect.stringMatching(/^1\n$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-item should echo the item at the given index', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST='hey ho'; list-get-item LIST 1`, execOpts)
  const expectedOut = expect.stringMatching(/^ho\n$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-item should handle newline seperator', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=$(echo -en "hey\nho"); list-get-item LIST 1 '\n'`, execOpts)
  const expectedOut = expect.stringMatching(/^ho\n$/)
  assertMatchNoError(result, expectedOut)
})

test(`list-get-item should handle ';' seperator`, () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST="hey;ho"; list-get-item LIST 1 ";"`, execOpts)
  const expectedOut = expect.stringMatching(/^ho\n$/)
  assertMatchNoError(result, expectedOut)
})
