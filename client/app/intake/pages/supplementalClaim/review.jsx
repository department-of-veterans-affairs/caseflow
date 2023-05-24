import React from 'react';
import * as yup from 'yup';
import { selectClaimantValidations } from '../../components/SelectClaimant';
import { FORM_TYPES, GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const supplementalClaimHeader = (veteranName) => (
  <h1>Review { veteranName }'s { FORM_TYPES.SUPPLEMENTAL_CLAIM.name }</h1>
);

const reviewSupplementalClaimSchema = yup.object().shape({
  'filed-by-va-gov': yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...receiptDateInputValidation(true),
  'benefit-type-options': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'different-claimant-option': yup.string().required(GENERIC_FORM_ERRORS.blank),
  'legacy-opt-in': yup.string().required(GENERIC_FORM_ERRORS.blank),
  ...selectClaimantValidations(),
});

export {
  reviewSupplementalClaimSchema,
  supplementalClaimHeader };
