
import React from 'react';
import PropTypes from 'prop-types';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import Button from 'app/components/Button';
import COPY from '../../../COPY';

const cancelLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: ACTIONS.REVERT_LEVERS,
  });
};
const refreshLevers = () => {
  window.location.reload(false);
};

export const LeverCancelButton = ({ leverStore }) => {
  const cancelButtonActions = () => {
    cancelLeverChanges(leverStore);
    refreshLevers();
  };

  return (
    <Button
      style={{ background: 'none', color: 'blue', 'font-weight': '300' }}
      id="CancelLeversButton"
      classNames={['cf-btn-link']}
      onClick={() => cancelButtonActions(leverStore)}>
      {COPY.CASE_DISTRIBUTION_LEVER_CANCEL_BUTTON}
    </Button>
  );
};
LeverCancelButton.propTypes = {
  leverStore: PropTypes.any
};
