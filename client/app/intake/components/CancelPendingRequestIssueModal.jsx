import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import { formatDateStr } from 'app/util/DateUtil';
import { capitalize } from 'lodash';

export const CancelPendingRequestIssueModal = (props) => {

  const {
    pendingIssue,
    removeIndex,
    onCancel,
    removeFromPendingReviewSection,
    toggleCancelPendingRequestIssueModal
  } = props;

  const displayWithdrawalDate = (issue) => {
    return (
      <><strong>Request date for withdrawal: </strong>{formatDateStr(issue.withdrawalDate)}<br /></>
    );
  };

  const displayRequestReason = (issue) => {
    return (
      <><strong>{capitalize(issue.requestType)} request reason: </strong>{issue.requestReason}<br /></>
    );
  };

  const displayIssueInformation = (issue) => {
    const issueHeader = issue.requestType === 'addition' ||
      issue.requestType === 'modification' ? 'Pending issue request' : 'Current issue';

    return (
      <div>
        <h2 style={{ marginBottom: '0px' }}>{issueHeader}</h2>
        <strong>Issue type: </strong>
        {issue?.nonratingIssueCategory ? issue.nonratingIssueCategory : issue.category}<br />
        <strong>Decision date: </strong>{formatDateStr(issue.decisionDate)}<br />
        <strong>Issue description: </strong>{issue.nonratingIssueDescription || issue.nonRatingIssueDescription}<br />
        {issue.requestType === 'withdrawal' ? displayWithdrawalDate(issue) : null}
        {issue.requestType ? displayRequestReason(issue) : null}
      </div>
    );
  };

  const modalInformation = () => {
    switch (pendingIssue.requestType) {
    case 'modification':
      return (
        <>
          {displayIssueInformation(pendingIssue.requestIssue)}
          {displayIssueInformation(pendingIssue)}
        </>
      );
    case 'addition':
      return (
        <>
          {displayIssueInformation(pendingIssue)}
        </>
      );
    case 'removal':
      return (
        <>
          {displayIssueInformation(pendingIssue)}
        </>
      );
    case 'withdrawal':
      return (
        <>
          {displayIssueInformation(pendingIssue)}
        </>
      );
    default:
    }
  };

  const handleSubmit = () => {
    removeFromPendingReviewSection(removeIndex);
    toggleCancelPendingRequestIssueModal();
  };

  return (
    <Modal
      title="Cancel pending request"
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
          name: 'Cancel',
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Submit request',
          onClick: handleSubmit
        }
      ]}
      closeHandler={onCancel}
    >
      {modalInformation()}
    </Modal>
  );
};

CancelPendingRequestIssueModal.propTypes = {
  pendingIssue: PropTypes.object,
  removeIndex: PropTypes.number,
  onCancel: PropTypes.func,
  removeFromPendingReviewSection: PropTypes.func,
  toggleCancelPendingRequestIssueModal: PropTypes.func
};
