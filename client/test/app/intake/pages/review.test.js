import {TestableSchema} from 'app/intake/pages/review';

const assertValidSchema = async (schema, testSchema, isValid) => {
  await schema
    .isValid(testSchema)
    .then((valid) => expect(valid).toBe(isValid))
}

describe('schema', () => {
  it('is valid after feb 19, 2019', async () => {
    const validSchema = { receiptDate: '01/01/2020' }
    await assertValidSchema(TestableSchema, validSchema, true)
  })
  it('is invalid before feb 19, 2019', async () => {
    const invalidSchema = { receiptDate: '02/18/2019' }
    await assertValidSchema(TestableSchema, invalidSchema, false)
  })
});