import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import {
  CONFIRM_CLAIM_LABEL_MODAL_TITLE,
  CONFIRM_CLAIM_LABEL_MODAL_BODY,
} from 'app/../COPY';

import EP_CLAIM_TYPES from 'constants/EP_CLAIM_TYPES';

export const ConfirmClaimLabelModal = ({ previousEpCode, newEpCode, onCancel, onSubmit, loading }) => {

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
        previousEpCode,
        newEpCode
      }),
    },
  ];

  /* eslint-disable camelcase */
  return (
    <Modal
      title={CONFIRM_CLAIM_LABEL_MODAL_TITLE}
      buttons={buttons}
      closeHandler={onCancel}
      id="confirm-claim-label-modal"
    >

      <div style={{ marginBottom: '24px' }}>
        <strong>
          Previous label: {EP_CLAIM_TYPES[previousEpCode]?.official_label}
          <br />
          New label: {EP_CLAIM_TYPES[newEpCode]?.official_label}
        </strong>
      </div>
      <p>{CONFIRM_CLAIM_LABEL_MODAL_BODY}</p>
    </Modal>
  );
  /* eslint-enable camelcase */
};

ConfirmClaimLabelModal.propTypes = {
  previousEpCode: PropTypes.string.isRequired,
  newEpCode: PropTypes.string.isRequired,
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  loading: PropTypes.bool.isRequired
};
