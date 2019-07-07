/* global test, expect */
import { assertMatchNoError, shell, execOpts } from '../testlib'

test('list-add-item should append items', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=''; list-add-item LIST a; echo "1: $LIST"; list-add-item LIST b; echo -n "2: $LIST"`, execOpts)
  const expectedOut = expect.stringMatching(/^1: a\n2: a\nb$/)
  assertMatchNoError(result, expectedOut)
})

test('list-add-item should handle spaces within items', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=''; list-add-item LIST 'a b'; echo -e "$LIST"; list-add-item LIST 'c d'; echo -en "$LIST"`, execOpts)
  const expectedOut = expect.stringMatching(/^a b\na b\nc d$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-index should echo index of item if present', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=hey$'\n'ho; list-get-index LIST ho`, execOpts)
  const expectedOut = expect.stringMatching(/^1\n$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-index should echo "" if item not present', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=hey$'\n'there; list-get-index LIST flaw`, execOpts)
  const expectedOut = expect.stringMatching(/^$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-item should echo the item at the given index, with no space', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=hey$'\n'ho; list-get-item LIST 1`, execOpts)
  const expectedOut = expect.stringMatching(/^ho$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-item should handle spaces in items', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=billy$'\n''hey there'; list-get-item LIST 1 '\n'`, execOpts)
  const expectedOut = expect.stringMatching(/^hey there$/)
  assertMatchNoError(result, expectedOut)
})

test('list-get-item out of bounds request should echo ""', () => {
  const result =
    shell.exec(`set -e; source src/data/lists.func.sh; LIST=billy$'\n''hey there'; list-get-item LIST 80 '\n'`, execOpts)
  const expectedOut = expect.stringMatching(/^$/)
  assertMatchNoError(result, expectedOut)
})
