import React from 'react';
import * as yup from 'yup';
import { selectClaimantValidations } from '../../components/SelectClaimant';
import { FORM_TYPES, GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const higherLevelReviewFormHeader = (veteranName) => (
  <h1>Review { veteranName }'s { FORM_TYPES.HIGHER_LEVEL_REVIEW.name }</h1>
);

const reviewHigherLevelReviewSchema = (yup.object().shape({
  ...receiptDateInputValidation(true),
  'benefit-type-options': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'informal-conference': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'different-claimant-option': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'legacy-opt-in': yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...selectClaimantValidations()
}));

const reviewHigherLevelReviewFiledByVaGov = (yup.object().shape({
  'filed-by-va-gov': yup.string().required(GENERIC_FORM_ERRORS.blank)
}));

const reviewHigherLevelReviewSameOffice = (yup.object().shape({
  'same-office': yup.string().required(GENERIC_FORM_ERRORS.blank)
}));

export {
  reviewHigherLevelReviewSchema,
  reviewHigherLevelReviewFiledByVaGov,
  reviewHigherLevelReviewSameOffice,
  higherLevelReviewFormHeader
};
