import {reviewAppealSchema} from 'app/intake/pages/appeal/review';
import { REVIEW_OPTIONS } from 'app/intake/constants';

const assertValidSchema = async (schema, testSchema, selectedForm, useAmaActivationDate, isValid) => {
  await schema
    .isValid(testSchema, { context: {selectedForm: selectedForm, useAmaActivationDate: useAmaActivationDate}})
    .then((valid) => expect(valid).toBe(isValid))
}

const BEFORE_AMA_DATE = '02/18/2019'
const AFTER_AMA_DATE = '02/20/2019'

const BEFORE_AMA_TEST_DATE = '10/31/2017'
const AFTER_AMA_TEST_DATE = '11/02/2017'

describe('schema', () => {
  describe('useAmaActivationDate', () => {
    it('is valid after feb 19, 2019', async () => {
      const validSchema = { receiptDate: AFTER_AMA_DATE }
      await assertValidSchema(reviewAppealSchema, validSchema, REVIEW_OPTIONS.APPEAL.key, true, true)
    })
    it('is invalid before feb 19, 2019', async () => {
      const invalidSchema = { receiptDate: BEFORE_AMA_DATE }
      await assertValidSchema(reviewAppealSchema, invalidSchema, REVIEW_OPTIONS.APPEAL.key, true, false)
    })
    it('is valid before feb 19, 2019 if not appeal', async () => {
      const validSchema = { receiptDate: BEFORE_AMA_DATE }
      await assertValidSchema(reviewAppealSchema, validSchema, 'not_appeal', true, true)
    })
  })
  describe('!useAmaActivationDate', () => {
    it('is valid after nov 1, 2017', async () => {
      const validSchema = { receiptDate: AFTER_AMA_TEST_DATE }
      await assertValidSchema(reviewAppealSchema, validSchema, REVIEW_OPTIONS.APPEAL.key, false, true)
    })
    it('is invalid before nov 1, 2017', async () => {
      const invalidSchema = { receiptDate: BEFORE_AMA_TEST_DATE }
      await assertValidSchema(reviewAppealSchema, invalidSchema, REVIEW_OPTIONS.APPEAL.key, false, false)
    })
    it('is valid before nov 1, 2017 if not appeal', async () => {
      const validSchema = { receiptDate: BEFORE_AMA_TEST_DATE }
      await assertValidSchema(reviewAppealSchema, validSchema, 'not_appeal', true, true)
    })
  })
});