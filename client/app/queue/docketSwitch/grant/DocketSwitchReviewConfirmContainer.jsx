import React from 'react';

import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import { appealWithDetailSelector } from '../../selectors';
import { DocketSwitchReviewConfirm } from './DocketSwitchReviewConfirm';

export const DocketSwitchReviewConfirmContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const docketType = useSelector(
    (state) => state.docketSwitch.formData.docketType
  );

  return <DocketSwitchReviewConfirm />;
};
