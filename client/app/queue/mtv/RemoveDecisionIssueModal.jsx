import React from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY';
import Modal from '../../components/Modal';

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
      <span className="delete-decision-modal">
        {COPY.DECISION_ISSUE_CONFIRM_DELETE}
        {/* {toDeleteHasConnectedIssue && COPY.DECISION_ISSUE_CONFIRM_DELETE_WITH_CONNECTED_ISSUES} */}
      </span>
    </Modal>
  );
};
RemoveDecisionIssueModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
