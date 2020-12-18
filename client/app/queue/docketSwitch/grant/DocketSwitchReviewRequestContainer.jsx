import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { stepForward } from '../docketSwitchSlice';
import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';
import { useHistory, useParams } from 'react-router';
import { appealWithDetailSelector } from '../../selectors';

export const DocketSwitchReviewRequestContainer = () => {
  const dispatch = useDispatch();
  const { appealId } = useParams();
  const { goBack } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const handleCancel = () => goBack();
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
