import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextField from '../../../components/TextField';
import COPY from '../../../../COPY';
import ApiUtil from '../../../util/ApiUtil';
import Alert from '../../../components/Alert';
import { sprintf } from 'sprintf-js';

const newContractor = {
  id: '',
  name: '',
  directory: '',
  poc: '',
  phone: '',
  email: ''
};

export const AddEditContractorModal = ({ onCancel, onConfirm, transcriptionContractor = newContractor }) => {
  const edit = transcriptionContractor.id !== '';
  const title = edit ?
    sprintf(COPY.TRANSCRIPTION_SETTINGS_EDIT, transcriptionContractor.name) : COPY.TRANSCRIPTION_SETTINGS_ADD;
  const [formData, setFormData] = useState(transcriptionContractor);
  const [serverError, setServerError] = useState(false);
  const [formValid, setFormValid] = useState(false);

  const addContractor = (contractorFormData) => {
    const data = {
      transcription_contractor: contractorFormData
    };

    ApiUtil.post('/hearings/find_by_contractor', { data }).
      then((response) => {

        if (response.body.transcription_contractor) {
          const contractor = response.body.transcription_contractor;

          onConfirm({
            transcription_contractor: contractor,
            alert: {
              title: sprintf(COPY.TRANSCRIPTION_SETTINGS_CREATE_MESSAGE, contractor.name),
              message: '',
              type: 'success'
            }
          });
        }
      }, () => {
        setServerError(true);
      });
  };

  const updateContractor = (contractorFormData) => {
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
              message: sprintf(COPY.TRANSCRIPTION_SETTINGS_UPDATE_MESSAGE, contractor.name),
              type: 'success'
            }
          });
        }
      }, () => {
        setServerError(true);
      });
  };

  const handleConfirm = () => {
    if (edit) {
      updateContractor(formData);
    } else {
      addContractor(formData);
    }
  };

  const validateForm = () => {
    setFormValid(
      formData.name.length &&
      formData.directory.length &&
      formData.poc.length &&
      formData.phone.length &&
      formData.email.length
    );
  };

  useEffect(() => {
    validateForm();
  }, [formData]);

  const handleChange = (name, value) => {
    setFormData((prevFormData) => ({ ...prevFormData, [name]: value }));
  };

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: COPY.TRANSCRIPTION_SETTINGS_CANCEL,
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: edit ? COPY.TRANSCRIPTION_SETTINGS_CONFIRM : COPY.TRANSCRIPTION_SETTINGS_ADD,
          onClick: handleConfirm,
          disabled: !formValid,
        },
      ]}
      closeHandler={onCancel}
      id="custom-contractor-modal"
    >
      {serverError &&
        <Alert title={COPY.TRANSCRIPTION_SETTINGS_ERROR_TITLE}
          message={COPY.TRANSCRIPTION_SETTINGS_ERROR_MESSAGE} type="error" /> }

      {!edit && <p>{COPY.TRANSCRIPTION_SETTINGS_ADD_FORM_DESCRIPTION}</p>}
      {edit && <p>{COPY.TRANSCRIPTION_SETTINGS_EDIT_FORM_DESCRIPTION}</p>}

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_NAME}
        name="name"
        defaultValue={formData.name}
        onChange={(value) => handleChange('name', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_DIRECTORY}
        name="directory"
        defaultValue={formData.directory}
        onChange={(value) => handleChange('directory', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_POC}
        name="poc"
        defaultValue={formData.poc}
        onChange={(value) => handleChange('poc', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_PHONE}
        name="phone"
        defaultValue={formData.phone}
        onChange={(value) => handleChange('phone', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_EMAIL}
        name="email"
        defaultValue={formData.email}
        onChange={(value) => handleChange('email', value)} />
    </Modal>
  );
};

AddEditContractorModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  transcriptionContractor: PropTypes.object
};

