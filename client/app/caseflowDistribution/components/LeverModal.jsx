import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import ApiUtil from '../../util/ApiUtil';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import moment from 'moment';

function changedOptionValue(changedLever, currentLever) {
  if (changedLever.data_type === 'radio' || changedLever.data_type === 'radio') {
    const changedOptionValue = changedLever.options.find((option) => option.item === changedLever.value).value;
    const currentOptionValue = currentLever.options.find((option) => option.item === currentLever.value)?.value;

    return changedOptionValue !== currentOptionValue;
  }

  return false;

}

function GenerateLeverUpdateData(leverStore) {
  const levers = leverStore.getState().levers;
  const initialLevers = leverStore.getState().initial_levers;
  const filteredLevers = levers.filter((lever, i) =>
    lever.value !== initialLevers[i].value || changedOptionValue(lever, initialLevers[i])
  );

  const filteredInitialLevers = initialLevers.filter((lever, i) =>
    initialLevers[i].value !== levers[i].value || changedOptionValue(initialLevers[i], levers[i])
  );

  return ([filteredLevers, filteredInitialLevers]);
}

function GenerateLeverHistory(filteredLevers, filteredInitialLevers) {
  let history = [];

  filteredLevers.map((lever, index) => {
    const doesDatatypeRequireComplexLogic = lever.data_type === 'radio' || lever.data_type === 'combination';

    let today = new Date();
    let todaysDate = moment(today).format('ddd MMM DD hh:mm:ss YYYY');

    if (doesDatatypeRequireComplexLogic) {
      const selectedOption = lever.options.find((option) => option.item === lever.value);
      const previousSelectedOption = filteredInitialLevers[index].options.find((option) => option.item === filteredInitialLevers[index].value);
      const isSelectedOptionANumber = selectedOption.data_type === 'number';
      const isPreviouslySelectedOptionANumber = previousSelectedOption.data_type === 'number';

      history.push(
        {
          created_at: todaysDate,
          title: lever.title,
          original_value: isPreviouslySelectedOptionANumber ? previousSelectedOption.value : previousSelectedOption.text,
          current_value: isSelectedOptionANumber ? selectedOption.value : selectedOption.text,
          unit: lever.unit
        }
      );
    } else {
      history.push(
        {
          created_at: todaysDate,
          title: lever.title,
          original_value: filteredInitialLevers[index].value,
          current_value: lever.value,
          unit: lever.unit
        }
      );
    }
  });

  return history;
}
function UpdateLeverHistory(leverStore) {
  let [filteredLevers, filteredInitialLevers] = GenerateLeverUpdateData(leverStore);

  leverStore.dispatch({
    type: Constants.FORMAT_LEVER_HISTORY,
    history: GenerateLeverHistory(filteredLevers, filteredInitialLevers)
  });
}

function setShowSuccessBanner(leverStore) {
  leverStore.dispatch({
    type: Constants.SHOW_SUCCESS_BANNER,
  });
  setTimeout(() => {
    leverStore.dispatch({
      type: Constants.HIDE_SUCCESS_BANNER,
    });
  }, 10000);
}

function leverValueDisplay(lever, isPreviousValue) {
  const doesDatatypeRequireComplexLogic = lever.data_type === 'radio' || lever.data_type === 'combination';

  if (doesDatatypeRequireComplexLogic) {
    const selectedOption = lever.options.find((option) => option.item === lever.value);
    const isSelectedOptionANumber = selectedOption.data_type === 'number';

    return isSelectedOptionANumber ? selectedOption.value : selectedOption.text;
  }

  return isPreviousValue ? lever.value : <strong>{lever.value}</strong>;
}

function SaveLeverChanges(leverStore) {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
    saveChangesActivated: true,
  });
}

function ShowSuccessBanner(shouldShowSuccessBanner) {
  leverStore.dispatch({
    type: Constants.SHOW_SUCCESS_BANNER,
    showSuccessBanner: shouldShowSuccessBanner,
  });
}

function SaveLeversToDB(leverStore) {
  const leversData = leverStore.getState().levers;

  UpdateLeverHistory(leverStore);
  const auditData = leverStore.getState().formatted_history;

  const postData = {
    current_levers: leversData,
    audit_lever_entries: auditData
  };

  return ApiUtil.post('/case_distribution_levers/update_levers_and_history', { data: postData }).
    then(() => {
      SaveLeverChanges(leverStore);
    }).
    catch((error) => {
      if (error.response) {
        console.error('Error:', error);
      }
    });
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

export function LeverSaveButton({ leverStore }) {
  const [showModal, setShowModal] = useState(false);
  const [changesOccurred, setChangesOccurred] = useState(false);

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

  const handleConfirmButton = async () => {
    await SaveLeversToDB(leverStore);
    setShowSuccessBanner(leverStore);
    setShowModal(false);
    ShowSuccessBanner(true);
  };

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
