import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import ApiUtil from '../../util/ApiUtil';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';

function updateLeverHistory(leverStore) {
  leverStore.dispatch({
    type: Constants.FORMAT_LEVER_HISTORY,
  });
}

function saveLeverChanges(leverStore)  {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
    saveChangesActivated: true,
  });
}

function saveLeversToDB(leverStore) {
  const leversData = leverStore.getState().levers;

  const postData = {
    current_levers: leversData,
    audit_lever_entries: [],
  }

  return ApiUtil.post('/case_distribution_levers/update_levers_and_history', { data: postData })
    .then(() => {
      // updateLeverHistory(leverStore);
      saveLeverChanges(leverStore);
    })
    .catch((error) => {
      if(error.response) {
        console.error('Error:', error);
      }
    });
}

function changedOptionValue(changedLever, currentLever) {
  if (changedLever.data_type === 'radio' || changedLever.data_type === 'radio') {
    const changedOptionValue = changedLever.options.find(option => option.item === changedLever.value).value
    const currentOptionValue = currentLever.options.find(option => option.item === currentLever.value)?.value
    return changedOptionValue !== currentOptionValue
  } else {
    return false
  }
}

function leverList(leverStore) {
  const levers = leverStore.getState().levers;
  const initialLevers = leverStore.getState().initial_levers;
  const filteredLevers = levers.filter((lever, i) => lever.value !== initialLevers[i].value || changedOptionValue(lever, initialLevers[i]));
  const filteredInitialLevers = initialLevers.filter((lever, i) => initialLevers[i].value !== levers[i].value || changedOptionValue(initialLevers[i], levers[i]));

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
          {filteredLevers.map((lever, index) => (
            <tr key={index}>
              <React.Fragment>
                <td className={`${styles.modalTableStyling} ${styles.modalTableLeftStyling}`}>{lever.title}</td>
                <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>
                  {leverValueDisplay(filteredInitialLevers[index], true)}
                </td>
                <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}>
                  {leverValueDisplay(lever, false)}
                </td>
              </React.Fragment>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function LeverSaveButton({ leverStore, onConfirmButtonClick }) {
  const [showModal, setShowModal] = useState(false);
  const [changesOccurred, setChangesOccurred] = useState(false);
  const [saveButtonDisabled, setSaveButtonDisabled] = useState(false);

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();
      console.log('Levers:', state.levers);
      console.log('Initial Levers:', state.initial_levers);

      const leversString = JSON.stringify(state.levers);
      const initialLeversString = JSON.stringify(state.initial_levers);

      const leverChangesOccurred = leversString !== initialLeversString;

      console.log('Changes Occurred:', leverChangesOccurred);

      setChangesOccurred(leverChangesOccurred);
    });

    return () => {
      unsubscribe();
    };
  }, [leverStore]);

  const handleSaveButton = () => {
    if (changesOccurred) {
      setShowModal(true);
    }
  };

  const handleConfirmButton = async () => {
    await saveLeversToDB(leverStore);
    setShowModal(false);
    setSaveButtonDisabled(true);
    if (onConfirmButtonClick) {
      onConfirmButtonClick()
    }
  }
  return (
    <>
      <Button
        id="LeversSaveButton"
        onClick={handleSaveButton}
        disabled={!changesOccurred}
      >
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
