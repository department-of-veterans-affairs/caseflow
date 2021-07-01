import React from 'react';
import * as yup from 'yup';
import { GENERIC_FORM_ERRORS } from '../../constants';
import { receiptDateInputValidation } from '../receiptDateInput';

const rampElectionFormHeader = (veteranName) => (
  <h1>Review { veteranName }'s Opt-In Election Form</h1>
);

const reviewRampElectionSchema = yup.object().shape({
  ...receiptDateInputValidation(true),
  'opt-in-election': yup.string().required(GENERIC_FORM_ERRORS.blank)
});

export { rampElectionFormHeader, reviewRampElectionSchema };
