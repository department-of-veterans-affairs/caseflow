import React from 'react';
import PropTypes from 'prop-types';
import * as Constants from '../../reducers/Levers/leversActionTypes';

export function LeverCancelButton({leverStore}) {
  const cancelLeverChanges = () => {
    leverStore.dispatch({
      type: Constants.REVERT_LEVERS,
    });
    console.log("Reverted levers");
    console.log(leverStore.getState());
    // refresh page
  }

  return (
    <button id="CancelLeversButton" onClick={cancelLeverChanges}>
      Cancel
    </button>
  );
};

export function LeverSaveButton({leverStore}) {
  const saveLeverChanges = () => {
    leverStore.dispatch({
      type: Constants.SAVE_LEVERS,
    });
    console.log("Saved levers");
    console.log(leverStore.getState());
    // update lever history
      // create history row object
      // append history row object to formatted_history array
      // save history row object to database
      // refresh page
    // save levers to database
  }

  return (
    <button id="SaveLeversButton" onClick={saveLeverChanges}>
      Save
    </button>
  );
};

LeverCancelButton.PropTypes = {
  leverStore: PropTypes.any
};

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any
};
