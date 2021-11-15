import {reviewAppealSchema} from 'app/intake/pages/appeal/review';
import DATES from '../../../../constants/DATES'
import {subDays, addDays} from 'date-fns';

const assertValidSchema = async (schema, testSchema, useAmaActivationDate, isValid) => {
  await schema
    .isValid(testSchema, { context: {useAmaActivationDate: useAmaActivationDate}})
    .then((valid) => expect(valid).toBe(isValid))
}

const BEFORE_AMA_DATE = subDays(new Date(DATES.AMA_ACTIVATION), 1)
const AFTER_AMA_DATE = addDays(new Date(DATES.AMA_ACTIVATION), 1)

const BEFORE_AMA_TEST_DATE = subDays(new Date(DATES.AMA_ACTIVATION_TEST), 1)
const AFTER_AMA_TEST_DATE = addDays(new Date(DATES.AMA_ACTIVATION_TEST), 1)

const validReviewAppealData = {
  'receipt-date': AFTER_AMA_DATE,
  'docket-type': 'docket',
  'docket-type': 'type',
  'legacy-opt-in': 'true',
  'different-claimant-option': 'false',
  'filed-by-va-gov': 'false'
} 

describe('schema', () => {
  describe('useAmaActivationDate', () => {
    it('is valid after feb 19, 2019', async () => {
      await assertValidSchema(reviewAppealSchema, validReviewAppealData, true, true)
    })
    it('is invalid before feb 19, 2019', async () => {
      const invalidSchema = validReviewAppealData
      invalidSchema['receipt-date'] = BEFORE_AMA_DATE
      await assertValidSchema(reviewAppealSchema, invalidSchema, true, false)
    })
  })
  describe('!useAmaActivationDate', () => {
    it('is valid after nov 1, 2017', async () => {
      const validSchema = validReviewAppealData
      validSchema['receipt-date'] = AFTER_AMA_TEST_DATE
      await assertValidSchema(reviewAppealSchema, validReviewAppealData, false, true)
    })
    it('is invalid before nov 1, 2017', async () => {
      const invalidSchema = validReviewAppealData
      invalidSchema['receipt-date'] = BEFORE_AMA_TEST_DATE

      await assertValidSchema(reviewAppealSchema, invalidSchema, false, false)
    })
  })
});