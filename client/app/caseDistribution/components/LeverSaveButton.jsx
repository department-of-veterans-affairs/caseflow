import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import { haveLeversChanged } from '../reducers/levers/leversSelector';
import ApiUtil from '../../util/ApiUtil';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import moment from 'moment';

const changedOptionValue = (changedLever, currentLever) => {
  if (changedLever.data_type === ACD_LEVERS.radio || changedLever.data_type === ACD_LEVERS.radio) {
    const newChangedOptionValue = changedLever.options.find((option) => option.item === changedLever.value).value;
    const currentOptionValue = currentLever.options.find((option) => option.item === currentLever.value)?.value;

    return newChangedOptionValue !== currentOptionValue;
  }

  return false;
};

const generateLeverUpdateData = (leverStore) => {
  const levers = leverStore.getState().levers;
  const backendLevers = leverStore.getState().backendLevers;
  const filteredLevers = levers.filter((lever, i) =>
    lever.value !== backendLevers[i].value || changedOptionValue(lever, backendLevers[i])
  );

  const filteredBackendLevers = backendLevers.filter((lever, i) =>
    backendLevers[i].value !== levers[i].value || changedOptionValue(backendLevers[i], levers[i])
  );

  return ([filteredLevers, filteredBackendLevers]);
};
const generateLeverHistory = (filteredLevers, filteredBackendLevers) => {
  return filteredLevers.map((lever, index) => {
    const doesDatatypeRequireComplexLogic = (lever.data_type === ACD_LEVERS.radio ||
      lever.data_type === ACD_LEVERS.combination);

    let today = new Date();
    let todaysDate = moment(today).format('ddd MMM DD hh:mm:ss YYYY');

    if (doesDatatypeRequireComplexLogic) {
      const selectedOption = lever.options.find((option) => option.item === lever.value);
      const previousSelectedOption =
        filteredBackendLevers[index].options.find((option) => option.item === filteredBackendLevers[index].value);
      const isSelectedOptionANumber = selectedOption.data_type === ACD_LEVERS.number;
      const isPreviouslySelectedOptionANumber = previousSelectedOption.data_type === ACD_LEVERS.number;

      return {
        created_at: todaysDate,
        title: lever.title,
        original_value: isPreviouslySelectedOptionANumber ?
          previousSelectedOption.value : previousSelectedOption.text,
        current_value: isSelectedOptionANumber ? selectedOption.value : selectedOption.text,
        unit: lever.unit
      };
    }

    return {
      created_at: todaysDate,
      title: lever.title,
      original_value: filteredLevers[index].value,
      current_value: lever.value,
      unit: lever.unit
    };

  });
};

const updateLeverHistory = (leverStore) => {
  let [filteredLevers] = generateLeverUpdateData(leverStore);

  leverStore.dispatch({
    type: ACTIONS.FORMAT_LEVER_HISTORY,
    history: generateLeverHistory(filteredLevers, filteredLevers)
  });
};

const setShowSuccessBanner = (leverStore) => {
  leverStore.dispatch({
    type: ACTIONS.SHOW_SUCCESS_BANNER,
  });
  setTimeout(() => {
    leverStore.dispatch({
      type: ACTIONS.HIDE_SUCCESS_BANNER,
    });
  }, 10000);
};

const leverValueDisplay = (lever, isPreviousValue) => {
  const doesDatatypeRequireComplexLogic = (lever.data_type === ACD_LEVERS.radio ||
    lever.data_type === ACD_LEVERS.combination);

  if (doesDatatypeRequireComplexLogic) {
    const selectedOption = lever.options.find((option) => option.item === lever.value);
    const isSelectedOptionANumber = selectedOption.data_type === ACD_LEVERS.number;

    return isSelectedOptionANumber ? selectedOption.value : selectedOption.text;
  }

  return isPreviousValue ? lever.value : <strong>{lever.value}</strong>;
};

const saveLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: ACTIONS.SAVE_LEVERS,
    saveChangesActivated: true,
  });
};

const showSuccessBanner = (leverStore, shouldShowSuccessBanner) => {
  leverStore.dispatch({
    type: ACTIONS.SHOW_SUCCESS_BANNER,
    showSuccessBanner: shouldShowSuccessBanner,
  });
};

const saveLeversToDB = async (leverStore) => {
  try {
    const leversData = leverStore.getState().levers;

    updateLeverHistory(leverStore);
    const auditData = leverStore.getState().historyList;

    const postData = {
      current_levers: leversData,
      audit_lever_entries: auditData
    };

    await ApiUtil.post('/case_distribution_levers/update_levers_and_history', { data: postData });

    saveLeverChanges(leverStore);
  } catch (error) {
    if (error.response) {
      console.error('Error:', error);
    }
  }
};

const leverList = (leverStore) => {
  const levers = leverStore.getState().levers;
  const backendLevers = leverStore.getState().backendLevers;
  const filteredLevers = levers.filter((lever, i) =>
    lever.value !== backendLevers[i].value || changedOptionValue(lever, backendLevers[i]));
  const filteredBackendLevers = backendLevers.filter((lever, i) =>
    backendLevers[i].value !== levers[i].value || changedOptionValue(backendLevers[i], levers[i]));

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
                  {leverValueDisplay(filteredBackendLevers[index], true)}
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
};

export const LeverSaveButton = ({ leverStore }) => {
  const [showModal, setShowModal] = useState(false);
  const [changesOccurred, setChangesOccurred] = useState(false);

  useEffect(() => {
    const unsubscribe = leverStore.subscribe(() => {
      const state = leverStore.getState();

      const validChangeOccurred = state.changesOccurred;

      setChangesOccurred(validChangeOccurred);

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
    setShowSuccessBanner(leverStore);
    setShowModal(false);
    showSuccessBanner(true);
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
          closeHandler={() => setShowModal(false)}
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
};

LeverSaveButton.propTypes = {
  leverStore: PropTypes.any,
};
