import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { DocketSwitchReviewRequestForm } from './DocketSwitchReviewRequestForm';
import { useHistory, useParams } from 'react-router';
import { appealWithDetailSelector } from '../../selectors';
import { completeDocketSwitchGranted } from './docketSwitchGrantedSlice';

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
      parent_id: taskId,
      type: 'DocketSwitchGrantedTask',
      external_id: appeal.externalId,
      assigned_to_type: 'User',
      docket_name: appeal.docketName,
      reciept_date: formData.receiptDate,
      issues: appeal.issues,
      appeallant_name: appeal.appellantFullName
    };

    try {
      await dispatch(completeDocketSwitchGranted(data));

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
