import React from 'react';
import * as yup from 'yup';
import { REVIEW_OPTIONS, GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const rampRefilingHeader = (veteranName) => (
  <h1>Review { veteranName }'s 21-4138 RAMP Selection Form</h1>
);

const reviewRampRefilingSchema = yup.object().shape({
  ...receiptDateInputValidation(),
  optionSelected: yup.string().required(GENERIC_FORM_ERRORS.blank),
  appealDocket: yup.string().notRequired().
    when('optionSelected', {
      is: REVIEW_OPTIONS.APPEAL.key,
      then: yup.string().required(GENERIC_FORM_ERRORS.blank)
    }),
});

export { reviewRampRefilingSchema, rampRefilingHeader };
