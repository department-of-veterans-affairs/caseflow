
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import { resetLevers, resetAllLeverErrors } from '../reducers/levers/leversActions';

export const LeverCancelButton = () => {
  const theState = useSelector((state) => state);
  const dispatch = useDispatch();

  const cancelButtonActions = () => {
    dispatch(resetLevers(theState));
    dispatch(resetAllLeverErrors());
  };

  return (
    <Button
      style={{ background: 'none', color: 'blue', 'font-weight': '300' }}
      id="CancelLeversButton"
      classNames={['cf-btn-link']}
      onClick={() => cancelButtonActions()}>
      {COPY.CASE_DISTRIBUTION_LEVER_CANCEL_BUTTON}
    </Button>
  );
};

export default LeverCancelButton;

