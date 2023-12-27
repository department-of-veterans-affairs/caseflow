import React from 'react';
import PropTypes from 'prop-types';
import { ACTIONS } from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import Button from 'app/components/Button';

function CancelLeverChanges(leverStore) {
  leverStore.dispatch({
    type: ACTIONS.REVERT_LEVERS,
  });
}

function RefreshLevers () {
  window.location.reload(false);
}

function DisplayButtonLeverAlert(alert) {
  console.log('alert', alert);
}

export function LeverCancelButton({ leverStore }) {
  const CancelButtonActions = (leverStore) => {
    CancelLeverChanges(leverStore);
    RefreshLevers();
    DisplayButtonLeverAlert('Cancelled');
  };

  return (
    <Button
      style={{ background: 'none', color: 'blue', 'font-weight': '300' }}
      id="CancelLeversButton"
      classNames={['cf-btn-link']}
      onClick={() => CancelButtonActions(leverStore)}>
      Cancel
    </Button>
  );
}

LeverCancelButton.propTypes = {
  leverStore: PropTypes.any
};

