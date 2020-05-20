import React from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../../COPY';
import Modal from '../../../components/Modal';

export const RemoveDecisionIssueModal = ({ onCancel, onSubmit }) => {
  const buttons = [
    { classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel },
    { classNames: ['usa-button', 'usa-button-primary'],
      name: 'Yes, delete decision',
      onClick: onSubmit }
  ];

  return (
    <Modal buttons={buttons} closeHandler={onCancel} title="Delete decision">
      <span className="delete-decision-modal">{COPY.MTV_CHECKOUT_CONFIRM_REMOVE_DECISION_ISSUE}</span>
    </Modal>
  );
};
RemoveDecisionIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
