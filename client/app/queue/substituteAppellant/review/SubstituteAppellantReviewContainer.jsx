/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { showSuccessMessage } from 'app/queue/uiReducer/uiActions';
import { SubstituteAppellantReview } from './SubstituteAppellantReview';

import { cancel, stepBack, completeSubstituteAppellant } from '../substituteAppellant.slice';

import COPY from 'app/../COPY';

export const SubstituteAppellantReviewContainer = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();

  const { formData: existingValues } = useSelector(
    (state) => state.substituteAppellant
  );

  const handleBack = () => {
    dispatch(stepBack());
    history.goBack();
  };
  const handleCancel = () => {
    // Reset Redux store
    dispatch(cancel());

    // Redirect to Case Details page
    history.push(`/queue/appeals/${appealId}`);
  };

  const successMessage = {
    title: COPY.SUBSTITUTE_APPELLANT_SUCCESS_TITLE,
    detail: COPY.SUBSTITUTE_APPELLANT_SUCCESS_DETAIL,
  };

  const handleSubmit = async () => {
    // Here we'll dispatch completeSubstituteAppellant action to submit data from Redux to the API
    // TODO: wrap in try catch block
    const payload = existingValues // TODO: modify payload here
    const response = await dispatch(completeSubstituteAppellant(payload));

    // Redirect to Case Details page... but maybe for new appeal...?
    dispatch(showSuccessMessage(successMessage));
    history.push(`/queue/appeals/${appealId}`); // TODO: use response to set URL
  };

  return (
    <SubstituteAppellantReview
      existingValues={existingValues}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
/* eslint-enable */
