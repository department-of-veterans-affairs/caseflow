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
      // UpdateLeverHistory(leverStore);
      saveLeverChanges(leverStore);
    })
    .catch((error) => {
      if(error.response) {
        console.error('Error:', error);
      }
    });
}

function handleOptionText(lever) {
  const selectedOption = lever.options.find((option) => lever.value === option.item);

  if (selectedOption) {
    console.log('Selected Option:', selectedOption);
    console.log('Is NaN:', isNaN(selectedOption.value));

    if (!isNaN(selectedOption.value)) {
      return selectedOption.value;
    } else {
      return selectedOption.text;
    }
  }

  return null;
}

function leverList(leverStore) {
  const levers = leverStore.getState().levers;
  const initialLevers = leverStore.getState().initial_levers;
  console.log(levers)

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
              <td className={`${styles.modalTableStyling} ${styles.modalTableRightStyling}`}><strong>{handleOptionText(lever)}</strong></td>
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
const [saveButtonDisabled, setSaveButtonDisabled] = useState(false);

  const leverValuesChanged = () =>{
      const state = leverStore.getState();

      const leversString = JSON.stringify(state.levers);
      const initialLeversString = JSON.stringify(state.initial_levers);

      return leversString !== initialLeversString;
  }

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {

      setChangesOccurred(leverValuesChanged);

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
