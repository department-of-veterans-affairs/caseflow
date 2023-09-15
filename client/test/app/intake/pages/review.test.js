import { reviewAppealSchema } from 'app/intake/pages/appeal/review';
import DATES from '../../../../constants/DATES';
import { subDays, addDays } from 'date-fns';

// const assertValidSchema = async (schema, testSchema, isValid) => {

//   await schema
//     .isValid(testSchema, { context: { useAmaActivationDate } })
//     .then((valid) => expect(valid).toBe(isValid));
// };

// const BEFORE_AMA_DATE = subDays(new Date(DATES.AMA_ACTIVATION), 1);
// const AFTER_AMA_DATE = addDays(new Date(DATES.AMA_ACTIVATION), 1);

// const BEFORE_AMA_TEST_DATE = subDays(new Date(DATES.AMA_ACTIVATION_TEST), 1);
// const AFTER_AMA_TEST_DATE = addDays(new Date(DATES.AMA_ACTIVATION_TEST), 1);

// const validReviewAppealData = {
//   'receipt-date': AFTER_AMA_DATE,
//   'docket-type': 'docket',
//   'docket-type': 'type',
//   'homelessness-type': 'false',
//   'original-hearing-request-type': 'video',
//   'legacy-opt-in': 'true',
//   'different-claimant-option': 'false',
//   'filed-by-va-gov': 'false'
// };

describe('schema', () => {
  describe('hearing type', () => {
    // eslint-disable-next-line jest/expect-expect
    it('null hearing type is valid', async () => {
      const validSchema = validReviewAppealData;

      validSchema['original-hearing-request-type'] = null;
      await assertValidSchema(reviewAppealSchema, validSchema, true, true);
    });

    it('hearing type is valid', async () => {
      const validSchema = validReviewAppealData;

      await assertValidSchema(reviewAppealSchema, validSchema, true, true);
    });

    describe('homelessness-type', () => {
      it(' field is valid', async () => {
        await assertValidSchema(reviewAppealSchema, validReviewAppealData, true, true);
      });
    });

  });
});
