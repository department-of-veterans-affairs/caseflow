/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { SubstituteAppellantReview } from './SubstituteAppellantReview';

import { cancel, stepBack } from '../substituteAppellant.slice';

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
  const handleSubmit = async () => {
    // Here we'll dispatch completeSubstituteAppellant action to submit data from Redux to the API
    dispatch(completeSubstituteAppellant(existingValues));

    // Redirect to Case Details page... but maybe for new appeal...?
    history.push(`/queue/appeals/${appealId}`);
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
