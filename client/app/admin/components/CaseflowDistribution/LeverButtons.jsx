import React from 'react';
import PropTypes from 'prop-types';
import * as Constants from '../../reducers/Levers/leversActionTypes';
import Button from 'app/components/Button';

export function LeverCancelButton({leverStore }) {
  const cancelLeverChanges = () => {
    leverStore.dispatch({
      type: Constants.REVERT_LEVERS,
    });
    console.log('Reverted levers');
    console.log(leverStore.getState());
    // refresh page
  };

  return (
    <Button
    id="CancelLeversButton"
    onClick={cancelLeverChanges}
    classNames={['cf-btn-link']}
    >
      Cancel
    </Button>
  );
};

export function LeverSaveButton({leverStore }) {
  const saveLeverChanges = () => {
    leverStore.dispatch({
      type: Constants.SAVE_LEVERS,
    });
    console.log('Saved levers');
    console.log(leverStore.getState());
    // update lever history
      // create history row object
      // append history row object to formatted_history array
      // save history row object to database
      // refresh page
    // save levers to database
  }

  return (
    <Button id="SaveLeversButton" onClick={saveLeverChanges}>
      Save
    </Button>
  );
}

LeverCancelButton.propTypes = {
  leverStore: PropTypes.any
};

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any
};
