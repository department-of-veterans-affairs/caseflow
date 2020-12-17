import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { DocketSwitchDenialForm } from './DocketSwitchDenialForm';
import { completeDocketSwitchDenial } from './docketSwitchDenialSlice';
import { appealWithDetailSelector } from '../../selectors';
import DISPOSITIONS from '../../../../constants/DOCKET_SWITCH';


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
      disposition: "denied",
      receipt_date: formData.receiptDate,
      context: formData.context,
      task_id: taskId
    };

    try {
      await dispatch(completeDocketSwitchDenial(docketSwitch));

      push('/queue');
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
