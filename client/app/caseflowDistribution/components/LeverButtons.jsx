
import React from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import Button from 'app/components/Button';

const cancelLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: Constants.REVERT_LEVERS,
  });
};
const refreshLevers = () => {
  window.location.reload(false);
};

export const leverCancelButton = ({ leverStore }) => {
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
      Cancel
    </Button>
  );
};
leverCancelButton.propTypes = {
  leverStore: PropTypes.any
};
