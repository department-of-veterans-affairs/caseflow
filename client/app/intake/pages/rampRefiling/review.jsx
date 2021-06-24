import React from 'react';
import * as yup from 'yup';
import { REVIEW_OPTIONS, GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const rampRefilingHeader = (veteranName) => (
  <h1>Review { veteranName }'s 21-4138 RAMP Selection Form</h1>
);

const reviewRampRefilingSchema = yup.object().shape({
  ...receiptDateInputValidation(),
  'opt-in-election': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'appeal-docket': yup.string().notRequired().
    when('opt-in-election', {
      is: REVIEW_OPTIONS.APPEAL.key,
      then: yup.string().required(GENERIC_FORM_ERRORS.blank)
    }),
});

export { reviewRampRefilingSchema, rampRefilingHeader };
