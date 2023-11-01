import React from 'react';
import PropTypes from 'prop-types';
import * as Constants from '../../reducers/Levers/leversActionTypes';

function CancelLeverChanges(leverStore)  {
  leverStore.dispatch({
    type: Constants.REVERT_LEVERS,
  });
};

function SaveLeverChanges(leverStore)  {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
  });
};

function RefreshLevers () {
  window.location.reload(false); //PLACEHOLDER
  // Find levers div
  // refresh levers div
};

function UpdateLeverHistory(leverStore) {
  // create history row object
  // append history row object to formatted_history array
  // save history row object to database
  // refresh lever div
};

function SaveLeversToDB(leverStore) {
  //load the levers from leverStore.getState().levers into the DB
};

function DisplayButtonLeverAlert(alert) {
  console.log("alert", alert)
  //show small banner displaying the alert
};

function DisableSaveButton() {
  document.getElementById("SaveLeversButton").disabled = true;
}

export function LeverCancelButton({leverStore}) {
  const CancelButtonActions = (leverStore) => {
    CancelLeverChanges(leverStore);
    RefreshLevers();
    DisplayButtonLeverAlert("Cancelled")
  };

  return (
    <button style={{"background": "none", "color": "blue", "font-weight": "300"}} id="CancelLeversButton" onClick={() => CancelButtonActions(leverStore)}>
      Cancel
    </button>
  );
};

export function LeverSaveButton({leverStore}) {
  const SaveButtonActions = (leverStore) => {
    SaveLeverChanges(leverStore);
    DisableSaveButton();
    UpdateLeverHistory(leverStore);
    SaveLeversToDB(leverStore);
    DisplayButtonLeverAlert("Saved")
  };

  return (
    <button id="SaveLeversButton" onClick={() => SaveButtonActions(leverStore)}>
      Save
    </button>
  );
};

LeverCancelButton.propTypes = {
  leverStore: PropTypes.any
};

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any
};
