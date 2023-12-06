import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import ApiUtil from '../../util/ApiUtil';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import Alert from 'app/components/Alert';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';


function DisplayAlertBanner() {
  const staticSuccessBanner = {
    title: COPY.CASE_DISTRIBUTION_SUCCESSBANNER_TITLE,
    message: COPY.CASE_DISTRIBUTION_SUCCESSBANNER_DETAIL,
    type: 'success',
    scrollOnAlert: true,
    fixed: false,
  };
  const divStyle = {
      top: 0,
      left: 0,
      width: "100%",
      zIndex: 9999,
      position: 'absolute',
      margin: 0,
      padding: 0,
  }

  return (
    <div style={divStyle}>
      <Alert {...staticSuccessBanner} />
    </div>
  );
}


function UpdateLeverHistory(leverStore) {
  leverStore.dispatch({
    type: Constants.FORMAT_LEVER_HISTORY,
  });
}

function SaveLeverChanges(leverStore)  {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
  });
}

function SaveLeversToDB(leverStore) {
  const leversData = leverStore.getState().levers;

  const postData = {
    current_levers: leversData,
    audit_lever_entries: [],
  }

  ApiUtil.post('/case_distribution_levers/update_levers_and_history', { data: postData })
    .then(() => {
      // UpdateLeverHistory(leverStore);
      SaveLeverChanges(leverStore);
    })
    .catch((error) => {
      if(error.response) {
        console.error('Error:', error);
      }
    });
}

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
  const [saveButtonDisabled, setSaveButtonDisabled] = useState(false);
  const [displayAlert, setDisplayAlert] = useState(false);

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();

      const leversString = JSON.stringify(state.levers);
      const initialLeversString = JSON.stringify(state.initial_levers);

      const leverChangesOccurred = leversString !== initialLeversString;

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

  const handleConfirmButton = () => {
    SaveLeversToDB(leverStore);
    setShowModal(false);
    setSaveButtonDisabled(true);
    setDisplayAlert(true);
  }



  return (
    <>
      <Button id="LeversSaveButton"  onClick={handleSaveButton} disabled={!changesOccurred || saveButtonDisabled}>
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
      {displayAlert && <DisplayAlertBanner />}
    </>
  );
}

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any,
};
