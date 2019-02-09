const assertMatchNoError = (result, expectedOut) => {
  expect(result.stderr).toEqual('')
  expect(result.stdout).toEqual(expectedOut)
  expect(result.code).toBe(0)
}

export {
  assertMatchNoError
}
