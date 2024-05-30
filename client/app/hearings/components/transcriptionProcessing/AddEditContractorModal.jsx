import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import TextField from '../../../components/TextField';
import COPY from '../../../../COPY';

export const AddEditContractorModal = ({ onCancel, onConfirm, title }) => {

  const [formError, setFormError] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    directory: '',
    poc: '',
    phone: '',
    email: ''
  });

  const handleConfirm = () => {
    let error = false;

    if (!formData.name.length) {
      error = true;
    }

    if (!formData.directory.length) {
      error = true;
    }

    if (!formData.poc.length) {
      error = true;
    }

    if (!formData.phone.length) {
      error = true;
    }

    if (!formData.email.length) {
      error = true;
    }

    setFormError(error);
    if (!error) {

      // backend call WIP

      onConfirm();
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
          name: 'Cancel',
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: COPY.TRANSCRIPTION_SETTINGS_ADD,
          onClick: handleConfirm
        },
      ]}
      closeHandler={onCancel}
      id="custom-contractor-modal"
    >
      <p>{COPY.TRANSCRIPTION_SETTINGS_FORM_DESCRIPTION}</p>

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
  title: PropTypes.string
};

