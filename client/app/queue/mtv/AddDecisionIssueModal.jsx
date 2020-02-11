import React from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY';
import Modal from '../../components/Modal';

export const AddDecisionIssueModal = ({ onCancel, onSubmit }) => {
  const buttons = [
    { classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel },
    { classNames: ['usa-button', 'usa-button-primary'],
      name: 'Add Issue',
      onClick: onSubmit }
  ];

  return (
    <Modal buttons={buttons} closeHandler={onCancel} title="Add decision">
      <span className="add-decision-modal">{COPY.DECISION_ISSUE_MODAL_TITLE}</span>
    </Modal>
  );
};
AddDecisionIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
