/* global test, expect, beforeAll, afterAll */
import { assertMatchNoError } from '../testlib'
const shell = require('shelljs')

const execOpts = {
  shell  : shell.which('bash'),
  silent : true,
}

test('list-add-item should append items', () => {
  const result =
    shell.exec(`source src/files/lists.func.sh; LIST=''; list-add-item LIST a; echo $LIST; list-add-item LIST b; echo $LIST`, execOpts)
  const expectedOut = expect.stringMatching(/a\na b\n$/)
  assertMatchNoError(result, expectedOut)
})
