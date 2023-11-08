import React from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import Button from 'app/components/Button';

let cancelLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: Constants.REVERT_LEVERS,
  });
};

let saveLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
  });
};

let refreshLevers = () => {
  window.location.reload(false);
  // PLACEHOLDER
  // Find levers div
  // refresh levers div
};

let updateLeverHistory = (leverStore) => {
  // create history row object
  // append history row object to formatted_history array
  // save history row object to database
  // refresh lever div
};

let saveLeversToDB = (leverStore) => {
  // load the levers from leverStore.getState().levers into the DB
};

let displayButtonLeverAlert = (alert) => {
  console.log('alert', alert);
  // show small banner displaying the alert
};

let disableSaveButton = () => {
  document.getElementById('SaveLeversButton').disabled = true;
};

export let LeverCancelButton = (leverStore) => {
  const cancelButtonActions = (levStore) => {
    cancelLeverChanges(levStore);
    refreshLevers();
    displayButtonLeverAlert('Cancelled');
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

export let LeverSaveButton = (leverStore) => {
  const saveButtonActions = (levStore) => {
    saveLeverChanges(levStore);
    disableSaveButton();
    updateLeverHistory(levStore);
    saveLeversToDB(levStore);
    displayButtonLeverAlert('Saved');
  };

  return (
    <Button id="SaveLeversButton"
      onClick={() => saveButtonActions(leverStore)}>
      Save
    </Button>
  );
};

LeverCancelButton.propTypes = {
  leverStore: PropTypes.any
};

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any
};
