import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { stepForward } from '../docketSwitchSlice';
import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';
import { useParams } from 'react-router';
import { appealWithDetailSelector } from '../../selectors';

export const DocketSwitchReviewRequestContainer = () => {
  const dispatch = useDispatch();
  const { appealId } = useParams();
  // const { goBack, push } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

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
        appellantName={appeal.appellantFullName}
        appeal={appeal}
      />
    </>
  );
};
