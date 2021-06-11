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
  docketType: yup.string().required(GENERIC_FORM_ERRORS.blank),
  unlistedClaimant: yup.string().required(GENERIC_FORM_ERRORS.blank),
  legacyOptInApproved: yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...selectClaimantValidations()
});

export { reviewAppealSchema, appealFormHeader };
