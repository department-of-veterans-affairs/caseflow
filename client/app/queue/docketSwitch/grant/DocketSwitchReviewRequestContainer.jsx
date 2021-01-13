import React from 'react';
import { useDispatch, useSelector, useEffect } from 'react-redux';
import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';
import { useHistory, useParams } from 'react-router';
import { appealWithDetailSelector } from '../../selectors';
import { updateDocketSwitch, stepForward } from '../docketSwitchSlice'

export const DocketSwitchReviewRequestContainer = () => {
  const dispatch = useDispatch();
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  // Reminder to add code to clear docketSwitch redux store when we go back.
  const handleCancel = () => goBack();

  const handleSubmit = async (formData) => {

    const data = {
      formData: {
      disposition: formData.disposition,
      docketType: formData.docketType,
      receiptDate: formData.receiptDate,
      issueIds: formData.issueIds
     }
    }
    
    try {
      await dispatch(updateDocketSwitch(data));
      dispatch(stepForward());
      push(`/queue/appeals/${appealId}/tasks/${taskId}/docket_switch/checkout/grant/tasks`);
    } catch (error) {
      // Perhaps show an alert that indicates error, advise trying again...?
    }
  };

  return (
    <>
      <DocketSwitchReviewRequestForm
        onCancel={handleCancel}
        onSubmit={handleSubmit}
        appellantName={appeal.appellantFullName}
        issues={appeal.issues}
      />
    </>
  );
};
