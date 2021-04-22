/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { SubstituteAppellantTasksForm } from './SubstituteAppellantTasksForm';

import { stepForward, cancel, stepBack } from '../substituteAppellant.slice';

export const SubstituteAppellantTasksView = () => {
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
  const handleSubmit = async (formData) => {
    // Here we'll dispatch updateData action to update Redux store with our form data
    dispatch(updateData(formData));

    // Advance progressbar
    dispatch(stepForward());

    // Move to next page
    history.push(`/queue/appeals/${appealId}/substitute_appellant/review`);
  };

  return (
    <SubstituteAppellantTasksForm
      existingValues={existingValues}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
/* eslint-enable */
