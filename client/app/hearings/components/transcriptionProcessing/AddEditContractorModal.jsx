import React, { useState } from 'react';
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
  const [formError, setFormError] = useState(false);
  const [formData, setFormData] = useState(transcriptionContractor);
  const [serverError, setServerError] = useState(false);

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
              title: `${COPY.TRANSCRIPTION_SETTINGS_CREATE_SUCCESS} #${contractor.id}`,
              message: contractor.name,
              type: 'success'
            }
          });
        }
      }, () => {
        setServerError(true);
      });
  };

  const updateContractor = (contractorFormData) => {

    // call patch instead of setting it directly
    const contractor = contractorFormData;

    onConfirm({
      transcription_contractor: contractor,
      alert: {
        title: `${COPY.TRANSCRIPTION_SETTINGS_UPDATE_SUCCESS} #${contractor.id}`,
        message: contractor.name,
        type: 'success'
      }
    });
  };

  const handleConfirm = () => {
    let error = false;

    if (
      !formData.name.length ||
      !formData.directory.length ||
      !formData.poc.length ||
      !formData.phone.length ||
      !formData.email.length
    ) {
      error = true;
    }

    setFormError(error);
    if (!error) {
      if (edit) {
        updateContractor(formData);
      } else {
        addContractor(formData);
      }
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
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: COPY.TRANSCRIPTION_SETTINGS_CANCEL,
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: edit ? COPY.TRANSCRIPTION_SETTINGS_CONFIRM : COPY.TRANSCRIPTION_SETTINGS_ADD,
          onClick: handleConfirm
        },
      ]}
      closeHandler={onCancel}
      id="custom-contractor-modal"
    >
      {serverError &&
        <Alert title={COPY.TRANSCRIPTION_SETTINGS_ERROR_TITLE}
          message={COPY.TRANSCRIPTION_SETTINGS_ERROR_MESSAGE} type="error" /> }

      {!edit && <p>{COPY.TRANSCRIPTION_SETTINGS_FORM_DESCRIPTION}</p>}

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_NAME}
        name="name"
        defaultValue={formData.name}
        errorMessage={formError && !formData.name.length ? COPY.TRANSCRIPTION_SETTINGS_ERROR_NAME : null}
        onChange={(value) => handleChange('name', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_DIRECTORY}
        name="directory"
        defaultValue={formData.directory}
        errorMessage={formError && !formData.directory.length ? COPY.TRANSCRIPTION_SETTINGS_ERROR_DIRECTORY : null}
        onChange={(value) => handleChange('directory', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_POC}
        name="poc"
        defaultValue={formData.poc}
        errorMessage={formError && !formData.poc.length ? COPY.TRANSCRIPTION_SETTINGS_ERROR_POC : null}
        onChange={(value) => handleChange('poc', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_PHONE}
        name="phone"
        defaultValue={formData.phone}
        errorMessage={formError && !formData.phone.length ? COPY.TRANSCRIPTION_SETTINGS_ERROR_PHONE : null}
        onChange={(value) => handleChange('phone', value)} />

      <TextField
        label={COPY.TRANSCRIPTION_SETTINGS_LABEL_EMAIL}
        name="email"
        defaultValue={formData.email}
        errorMessage={formError && !formData.email.length ? COPY.TRANSCRIPTION_SETTINGS_ERROR_EMAIL : null}
        onChange={(value) => handleChange('email', value)} />
    </Modal>
  );
};

AddEditContractorModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  transcriptionContractor: PropTypes.object
};

