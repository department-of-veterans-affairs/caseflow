import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';


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
  const initialLevers = leverStore.getState().initial_levers;

  return (
    <div>
      <table>
        <tbody>
          <tr>
            <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableLeftStyling}`}>Data Element</th>
            <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>Previous Value</th>
            <th className={`${styles.modalTableHeaderStyling} ${styles.modalTableRightStyling}`}>New Value</th>
          </tr>
        </tbody>
        <tbody>
          {levers.map((lever, index) => (
            <tr key={index}>
              {lever.value !== initialLevers[index].value && (
                <React.Fragment>
              <td className={`${styles.modalTableStyling} ${styles.modalTableLeftStyling}`}>{lever.title}</td>
              <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>{initialLevers[index].value}</td>
              <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}><strong>{lever.value}</strong></td>
                </React.Fragment>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function LeverSaveButton({ leverStore }) {
  const [showModal, setShowModal] = useState(false);
  const [changesOccurred, setChangesOccurred] = useState(false);

  useEffect(() => {
    // Subscribe to changes in the lever store and update local state
    console.log({stateBefore: leverStore.getState()})
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();
      setChangesOccurred(state.changesOccurred);
      console.log({stateAfter: leverStore.getState()})
    });

    return () => {
      // Unsubscribe when the component unmounts
      unsubscribe();
    };
  }, [leverStore]);


  const handleSaveButton = () => {
    if (changesOccurred) {
      SaveLeversToDB(leverStore);
      UpdateLeverHistory(leverStore);
      SaveLeverChanges(leverStore);
      DisableSaveButton();
      setShowModal(true);
      DisplayButtonLeverAlert('');
    }
  };

  const handleConfirmButton = () => {
    setShowModal(false);
  }



  return (
    <>
      <Button id="SaveLeversButton"  onClick={handleSaveButton} disabled={!changesOccurred}>
        Save
      </Button>
      {showModal &&
      <Modal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        title={COPY.CASE_DISTRIBUTION_MODAL_TITLE}
        confirmButton={<Button onClick={handleConfirmButton}>{COPY.MODAL_CONFIRM_BUTTON}</Button>}
        cancelButton={<Button onClick={() => setShowModal(false)}>{COPY.MODAL_CANCEL_BUTTON}</Button>}
        className={styles.updatedModalStyling}
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
