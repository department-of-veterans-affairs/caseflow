/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';

import { SubstituteAppellantPoaForm } from './SubstituteAppellantPoaForm';

import { stepForward, cancel, stepBack } from '../substituteAppellant.slice';

export const SubstituteAppellantPoaView = () => {
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

    // Advance progressbar
    dispatch(stepForward());

    // Move to next page
    history.push(`/queue/appeals/${appealId}/substitute_appellant/tasks`);
  };

  return (
    <SubstituteAppellantPoaForm
      existingValues={existingValues}
      onBack={handleBack}
      onCancel={handleCancel}
      onSubmit={handleSubmit}
    />
  );
};
/* eslint-enable */
