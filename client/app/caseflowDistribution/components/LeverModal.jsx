import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import * as Constants from 'app/caseflowDistribution/reducers/Levers/leversActionTypes';
import ApiUtil from '../../util/ApiUtil';
import Modal from 'app/components/Modal';
import Button from 'app/components/Button';
import COPY from '../../../COPY';
import styles from 'app/styles/caseDistribution/InteractableLevers.module.scss';
import moment from 'moment';

//list is to define the order of the levers in the modal pop up and also history
const leversHistoryOrder = [
'alternative_batch_size',
'batch_size_per_attorney',
'request_more_cases_minimum',
'ama_hearing_case_affinity_days',
'ama_hearing_case_aod_affinity_days',
'cavc_affinity_days',
'cavc_aod_affinity_days',
'aoj_affinity_days',
'aoj_aod_affinity_days',
'aoj_cavc_affinity_days',
'ama_direct_review_docket_time_goals',
'ama_evidence_submission_docket_time_goals',
'ama_hearings_docket_time_goals',
'ama_hearings_start_distribution_prior_to_goals',
'ama_direct_review_start_distribution_prior_to_goals',
'ama_evidence_submission_start_distribution_prior_to_goals',
'maximum_direct_review_proportion',
'minimum_legacy_proportion',
'nod_adjustment',
'bust_backlog',
];

const changedOptionValue = (changedLever, currentLever) => {
  if (changedLever.data_type === 'radio' || changedLever.data_type === 'radio') {
    const newChangedOptionValue = changedLever.options.find((option) => option.item === changedLever.value).value;
    const currentOptionValue = currentLever.options.find((option) => option.item === currentLever.value)?.value;

    return newChangedOptionValue !== currentOptionValue;
  }

  return false;
};

const generateLeverUpdateData = (leverStore) => {
  const levers = leverStore.getState().levers;
  const initialLevers = leverStore.getState().initial_levers;
  const filteredLevers = levers.sort((a, b) => leversHistoryOrder.indexOf(a.item) - leversHistoryOrder.indexOf(b.item)).filter((lever, i) =>lever.value !== initialLevers[i].value || changedOptionValue(lever, initialLevers[i])
  );

  const filteredInitialLevers = initialLevers.sort((a, b) => leversHistoryOrder.indexOf(a.item) - leversHistoryOrder.indexOf(b.item)).filter((lever, i) => initialLevers[i].value !== levers[i].value || changedOptionValue(initialLevers[i], levers[i])
  );

  return ([filteredLevers, filteredInitialLevers]);
};
const generateLeverHistory = (filteredLevers, filteredInitialLevers) => {
  return filteredLevers.map((lever, index) => {
    const doesDatatypeRequireComplexLogic = lever.data_type === 'radio' || lever.data_type === 'combination';

    let today = new Date();
    let todaysDate = moment(today).format('ddd MMM DD hh:mm:ss YYYY');

    if (doesDatatypeRequireComplexLogic) {
      const selectedOption = lever.options.find((option) => option.item === lever.value);
      const previousSelectedOption =
        filteredInitialLevers[index].options.find((option) => option.item === filteredInitialLevers[index].value);
      const isSelectedOptionANumber = selectedOption.data_type === 'number';
      const isPreviouslySelectedOptionANumber = previousSelectedOption.data_type === 'number';

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
      original_value: filteredInitialLevers[index].value,
      current_value: lever.value,
      unit: lever.unit
    };

  });
};

const updateLeverHistory = (leverStore) => {
  let [filteredLevers, filteredInitialLevers] = generateLeverUpdateData(leverStore);

  leverStore.dispatch({
    type: Constants.FORMAT_LEVER_HISTORY,
    history: generateLeverHistory(filteredLevers, filteredInitialLevers)
  });
};

const setShowSuccessBanner = (leverStore) => {
  leverStore.dispatch({
    type: Constants.SHOW_SUCCESS_BANNER,
  });
  setTimeout(() => {
    leverStore.dispatch({
      type: Constants.HIDE_SUCCESS_BANNER,
    });
  }, 10000);
};

const leverValueDisplay = (lever, isPreviousValue) => {
  const doesDatatypeRequireComplexLogic = lever.data_type === 'radio' || lever.data_type === 'combination';

  if (doesDatatypeRequireComplexLogic) {
    const selectedOption = lever.options.find((option) => option.item === lever.value);
    const isSelectedOptionANumber = selectedOption.data_type === 'number';

    return isSelectedOptionANumber ? selectedOption.value : selectedOption.text;
  }

  return isPreviousValue ? lever.value : <strong>{lever.value}</strong>;
};

const saveLeverChanges = (leverStore) => {
  leverStore.dispatch({
    type: Constants.SAVE_LEVERS,
    saveChangesActivated: true,
  });
};

const showSuccessBanner = (leverStore, shouldShowSuccessBanner) => {
  leverStore.dispatch({
    type: Constants.SHOW_SUCCESS_BANNER,
    showSuccessBanner: shouldShowSuccessBanner,
  });
};

const saveLeversToDB = async (leverStore) => {
  try {
    const leversData = leverStore.getState().levers;

    updateLeverHistory(leverStore);
    const auditData = leverStore.getState().formatted_history;

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
  const initialLevers = leverStore.getState().initial_levers;
  const filteredLevers = levers.filter((lever, i) => lever.value !== initialLevers[i].value || changedOptionValue(lever, initialLevers[i])).sort((a, b) => leversHistoryOrder.indexOf(a.item) - leversHistoryOrder.indexOf(b.item));
  const filteredInitialLevers = initialLevers.filter((lever, i) => initialLevers[i].value !== levers[i].value || changedOptionValue(initialLevers[i], levers[i])).sort((a, b) => leversHistoryOrder.indexOf(a.item) - leversHistoryOrder.indexOf(b.item));

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
