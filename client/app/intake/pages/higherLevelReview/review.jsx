import React from 'react';
import * as yup from 'yup';
import { selectClaimantValidations } from '../../components/SelectClaimant';
import { FORM_TYPES, GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const higherLevelReviewFormHeader = (veteranName) => (
  <h1>Review { veteranName }'s { FORM_TYPES.HIGHER_LEVEL_REVIEW.name }</h1>
);

const reviewHigherLevelReviewSchema = yup.object().shape({
  benefitType: yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...receiptDateInputValidation(true),
  informalConference: yup.string().required(GENERIC_FORM_ERRORS.blank),
  sameOffice: yup.string().required(GENERIC_FORM_ERRORS.blank),
  claimant: yup.string().required(GENERIC_FORM_ERRORS.blank),
  legacyOptInApproved: yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...selectClaimantValidations()
});

export { reviewHigherLevelReviewSchema, higherLevelReviewFormHeader };
