import React, { useState } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import { formattedLevers } from 'test/data/formattedCaseDistributionData';
import COPY from '../../../COPY';


function SaveLeverChanges(leverStore)  {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
  });
};

function DisplayButtonLeverAlert(alert) {
  console.log("alert", alert)
  //show small banner displaying the alert
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
function DisableSaveButton() {
  document.getElementById("SaveLeversButton").disabled = true;
};
function leverList(leverStore) {
  const levers = leverStore.getState().levers;

  return (
    <table>
      <thead>
        <tr>
          <th>Data Element</th>
          <th>Previous Value</th>
          <th>New Value</th>
        </tr>
      </thead>
      <tbody>
        {levers.map((lever, index) => (
          <tr key={index}>
            <td>{lever.title}</td>
            <td>{lever.value}</td>
            <td>{lever.newValue}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}


export function LeverSaveButton({ leverStore }) {
  const [showModal, setShowModal] = useState(false);

  const handleSave = () => {
    SaveLeverChanges(leverStore);
    DisableSaveButton();
    UpdateLeverHistory(leverStore);
    SaveLeversToDB(leverStore);
    DisplayButtonLeverAlert('');
    setShowModal(false);
  };



  return (
    <>
      <Button id="SaveLeversButton" onClick={() => setShowModal(true)}>
        Save
      </Button>
      {showModal &&
      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={COPY.CASE_DISTRIBUTION_MODAL_TITLE}
        confirmButton={<Button onClick={handleSave}>{COPY.MODAL_CONFIRM_BUTTON}</Button>}
        cancelButton={<Button onClick={() => setShowModal(false)}>{COPY.MODAL_CANCEL_BUTTON}</Button>}
      >
        <p>{COPY.CASE_DISTRIBUTION_MODAL_DESCRIPTION}</p>
        {leverList(leverStore)}
      </Modal>
      }
    </>
  );
}

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any,
};
