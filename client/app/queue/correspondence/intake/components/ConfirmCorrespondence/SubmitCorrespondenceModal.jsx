import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import {
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE,
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY,
} from 'app/../COPY';

export const SubmitCorrespondenceModal = ({ setSubmitCorrespondenceModalVisible }) => {

  const [loading, setLoading] = useState(false);

  const onSubmit = () => {
    setLoading(true);

    return onSubmit();
  };

  const onCancel = () => {
    setSubmitCorrespondenceModalVisible(false);
  };

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel,
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Confirm',
      loading,
      onClick: () => onSubmit?.({
        // Where submitted data goes
      }),
    },
  ];

  /* eslint-disable camelcase */
  return (
    <Modal
      title={CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE}
      buttons={buttons}
      closeHandler={onCancel}
      id="submit-correspondence-intake-modal"
    >
      {CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY}
    </Modal>
  );
  /* eslint-enable camelcase */
};

SubmitCorrespondenceModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  loading: PropTypes.bool,
  setSubmitCorrespondenceModalVisible: PropTypes.func,
};
