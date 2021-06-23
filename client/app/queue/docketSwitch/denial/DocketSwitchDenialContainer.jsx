import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { DocketSwitchDenialForm } from './DocketSwitchDenialForm';
import { completeDocketSwitchDenial } from './docketSwitchDenialSlice';
import { appealWithDetailSelector } from '../../selectors';
import {
  DOCKET_SWITCH_DENIAL_SUCCESS_TITLE,
  DOCKET_SWITCH_DENIAL_SUCCESS_MESSAGE,
} from 'app/../COPY';
import { sprintf } from 'sprintf-js';
import { showSuccessMessage } from '../../uiReducer/uiActions';

export const DocketSwitchDenialContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const handleCancel = () => goBack();
  const handleSubmit = async (formData) => {

    const docketSwitch = {
      disposition: 'denied',
      receipt_date: formData.receiptDate,
      context: formData.context,
      task_id: taskId,
      old_docket_stream_id: appeal.id
    };

    const successMessage = {
      title: sprintf(DOCKET_SWITCH_DENIAL_SUCCESS_TITLE, appeal.appellantFullName),
      detail: DOCKET_SWITCH_DENIAL_SUCCESS_MESSAGE,
    };

    try {
      await dispatch(completeDocketSwitchDenial(docketSwitch));

      dispatch(showSuccessMessage(successMessage));
      push(`/queue/appeals/${appealId}`);
    } catch (error) {
      // Perhaps show an alert that indicates error, advise trying again...?
      console.error('Error Denying Docket Switch', error);
    }
  };

  return <DocketSwitchDenialForm
    appellantName={appeal.appellantFullName}
    onCancel={handleCancel}
    onSubmit={handleSubmit}
  />;
};
