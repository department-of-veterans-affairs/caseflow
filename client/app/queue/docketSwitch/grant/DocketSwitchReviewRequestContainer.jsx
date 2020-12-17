import React from 'react';
import { useDispatch } from 'react-redux';
import { stepForward } from '../docketSwitchSlice';
import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';

export const DocketSwitchReviewRequestContainer = () => {
  const dispatch = useDispatch();

  const handleCancel = () => {
    // Add code to clear docketSwitch redux store
    // You can utilize useHistory() react-router hook to go back to the case details page
  };
  const handleSubmit = () => {
    // Add stuff to redux store

    // Call stepForward redux action
    dispatch(stepForward());

    // Move to next step
  };

  return (
    <>
      <DocketSwitchReviewRequestForm
        onCancel={handleCancel}
        onSubmit={handleSubmit}
      />
    </>
  );
};
