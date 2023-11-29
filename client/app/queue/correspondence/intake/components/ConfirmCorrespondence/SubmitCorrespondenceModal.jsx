import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import {
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE,
  CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY,
} from 'app/../COPY';

export const SubmitCorrespondenceModal = ({ onCancel, onSubmit, loading }) => {

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

      <div style={{ marginBottom: '24px' }}>
        <strong>
          {CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_TITLE}
        </strong>
      </div>
      <p>{CORRESPONDENCE_INTAKE_FORM_SUBMIT_MODAL_BODY}</p>
    </Modal>
  );
  /* eslint-enable camelcase */
};

SubmitCorrespondenceModal.propTypes = {
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  loading: PropTypes.bool.isRequired
};
