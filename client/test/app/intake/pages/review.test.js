import {TestableSchema} from 'app/intake/pages/review';
import { REVIEW_OPTIONS } from 'app/intake/constants';

const assertValidSchema = async (schema, testSchema, selectedForm, isValid) => {
  await schema
    .isValid(testSchema, { context: {selectedForm: selectedForm}})
    .then((valid) => expect(valid).toBe(isValid))
}

describe('schema', () => {
  it('is valid after feb 19, 2019', async () => {
    const validSchema = { receiptDate: '01/01/2020' }
    await assertValidSchema(TestableSchema, validSchema, REVIEW_OPTIONS.APPEAL.key, true)
  })
  it('is invalid before feb 19, 2019', async () => {
    const invalidSchema = { receiptDate: '02/18/2019' }
    await assertValidSchema(TestableSchema, invalidSchema, REVIEW_OPTIONS.APPEAL.key, false)
  })
});