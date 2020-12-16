import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { DocketSwitchDenialForm } from './DocketSwitchDenialForm';
import { completeDocketSwitchDenial } from './docketSwitchDenialSlice';
import { appealWithDetailSelector } from '../../selectors';
import DISPOSITIONS from '../../../../constants/DOCKET_SWITCH';
import { createDocketSwitchRulingTask } from './docketSwitchDenialSlice';

export const DocketSwitchDenialContainer = () => {
  const { appealId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const handleCancel = () => goBack();
  const handleSubmit = async (formData) => {
    await dispatch(completeDocketSwitchDenial(formData));

    // Add success alert

    // Redirect to user's queue
    push('/queue');
  };

  return <DocketSwitchDenialForm
    appellantName={appeal.appellantFullName}
    onCancel={handleCancel}
    onSubmit={handleSubmit}
  />;
};
