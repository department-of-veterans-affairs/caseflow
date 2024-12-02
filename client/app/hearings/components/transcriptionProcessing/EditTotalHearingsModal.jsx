/* eslint-disable max-len */
/* eslint-disable max-statements-per-line */
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextField from '../../../components/TextField';
import COPY from '../../../../COPY';
import { sprintf } from 'sprintf-js';
import ApiUtil from '../../../util/ApiUtil';
import Alert from '../../../components/Alert';

const modalContentStyles = {
  '& h2': {
    margin: 0,
  },
  '& p': {
    marginTop: 0,
  },
  '& .input-container': {
    width: '73px'
  },
  '& .cf-form-textinput': {
    marginBottom: 0,
    position: 'relative'
  },
  '& label ': {
    position: 'absolute',
    left: '82px',
    bottom: '3px'
  },
  '& .usa-input-error': {
    marginBottom: 0
  },
  '& .usa-input-error label': {
    left: '115px',
    bottom: '13px'
  },
  '& .usa-alert': {
    marginBottom: '1.5em'
  }
};

export const EditTotalHearingsModal = ({ onCancel, onConfirm, transcriptionContractor }) => {
  const [formData, setFormData] = useState(transcriptionContractor);
  const [serverError, setServerError] = useState(false);
  const [formValid, setFormValid] = useState(true);
  const title = COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_MODAL_TITLE;

  const updateContractorTotalHearings = (contractorFormData) => {
    const data = {
      transcription_contractor: contractorFormData
    };

    ApiUtil.patch(`/hearings/find_by_contractor/${formData.id}`, { data }).
      then((response) => {

        if (response.body.transcription_contractor) {
          const contractor = response.body.transcription_contractor;

          onConfirm({
            transcription_contractor: contractor,
            alert: {
              title: COPY.TRANSCRIPTION_SETTINGS_CREATE_SUCCESS,
              message: sprintf(COPY.TRANSCRIPTION_SETTINGS_UPDATE_HEARINGS_GOAL_MESSAGE, contractor.name),
              type: 'success'
            }
          });
        }
      }, () => {
        setServerError(true);
      });
  };

  const validateForm = () => {
    const currentGoal = parseInt(formData.current_goal, 10);
    const valid = currentGoal >= 1 && currentGoal <= 1000;

    setFormValid(valid);

    return valid;
  };

  const handleConfirm = () => {
    if (validateForm()) {
      updateContractorTotalHearings(formData);
    }
  };

  const handleChange = (name, value) => {
    setFormData((prevFormData) => ({ ...prevFormData, [name]: value }));
  };

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ['cf-modal-link cf-btn-link'],
          name: 'Cancel',
          onClick: onCancel,
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: COPY.MODAL_CONFIRM_BUTTON,
          onClick: handleConfirm,
        },
      ]}
      closeHandler={onCancel}
      id="custom-total-hearings-modal"
    >
      <div style={modalContentStyles}>
        {serverError &&
          <Alert title={COPY.TRANSCRIPTION_SETTINGS_ERROR_TITLE}
            message={COPY.TRANSCRIPTION_SETTINGS_ERROR_MESSAGE} type="error" /> }

        <h2>{sprintf(COPY.TRANSCTIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_MODAL_CONTRACTOR, transcriptionContractor.name)}</h2>

        <p><strong>{sprintf(COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_MODAL_CURRENT_GOAL, transcriptionContractor.current_goal)}</strong></p>

        <TextField
          label={COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_MODAL_INPUT_TEXT}
          name="current_goal"
          defaultValue={formData.current_goal}

          errorMessage={formValid ? null : COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_VALIDATION}

          onChange={(value) => handleChange('current_goal', value)} />
      </div>
    </Modal>
  );
};

EditTotalHearingsModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func.isRequired,
  transcriptionContractor: PropTypes.object
};
