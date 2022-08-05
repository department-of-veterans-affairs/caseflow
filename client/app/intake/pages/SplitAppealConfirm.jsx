import React, { useContext } from 'react';
import { StateContext } from '../../intakeEdit/IntakeEditFrame';
import COPY from '../../../COPY';

const SplitAppealConfirm = () => {
  const { reason } = useContext(StateContext);

  return (
    <>
      <h1>{COPY.SPLIT_APPEAL_REVIEW_TITLE}</h1>
      <span>{COPY.SPLIT_APPEAL_REVIEW_SUBHEAD}</span>

      <br /><br />
      <u>{COPY.SPLIT_APPEAL_REVIEW_REASONING_TITLE}</u> <span>{reason}</span>
    </>
  );
};

export default SplitAppealConfirm;
