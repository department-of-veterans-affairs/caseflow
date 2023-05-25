import React from 'react';
import * as yup from 'yup';
import { selectClaimantValidations } from '../../components/SelectClaimant';
import { FORM_TYPES, GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const appealFormHeader = (veteranName) => (
  <h1>Review { veteranName }'s { FORM_TYPES.APPEAL.name }</h1>
);

const reviewAppealSchema = yup.object().shape({
  ...receiptDateInputValidation(true),
  'filed-by-va-gov': yup.string(),
  'docket-type': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'original-hearing-request-type': yup.string().nullable(true),
  'different-claimant-option': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'legacy-opt-in': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'homelessness-type': yup.string(),
  ...selectClaimantValidations()
});

export { reviewAppealSchema, appealFormHeader };
