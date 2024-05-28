import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import CurrentIssue from 'app/intakeEdit/components/RequestCommonComponents/CurrentIssue';
import { formatDateStr } from 'app/util/DateUtil';

export const CancelPendingRequestIssueModal = (props) => {

  const {
    pendingIssue,
    removeIndex,
    addIssue,
    onCancel,
    removeFromPendingReviewSection
  } = props;

  let displayIssueInformation = (issue) => {
    const issueHeader = issue.requestType === 'Addition' ||
      issue.requestType === 'Modification' ? 'Pending issue request' : 'Current issue';

    return (
      <div>
        <h2 style={{ marginBottom: '0px' }}>{issueHeader}</h2>
        <strong>Issue type: </strong>{issue.nonRatingIssueCategory}<br />
        <strong>Decision date: </strong>{formatDateStr(issue.decisionDate)}<br />
        <strong>Issue description: </strong>{issue.nonRatingIssueDescription}<br />
        {issue.requestType === 'Withdrawal' &&
          <><strong>Request date for withdrawal: </strong>{formatDateStr(issue.withdrawalDate)}<br /></>}
        <strong>{issue.requestType} request reason: </strong>{issue.requestReason}<br />
      </div>
    );
  };

  const modalInformation = () => {
    switch (pendingIssue.requestType) {
    case 'Modification':
      return (
        <>
          <CurrentIssue currentIssue={pendingIssue.requestIssue} />
          {displayIssueInformation(pendingIssue)}
        </>
      );
    case 'Addition':
      return (
        <>
          {displayIssueInformation(pendingIssue)}
        </>
      );
    case 'Removal':
      return (
        <>
          {displayIssueInformation(pendingIssue)}
        </>
      );
    case 'Withdrawal':
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
    if (pendingIssue.requestType !== 'Addition') {
      addIssue(pendingIssue.requestIssue);
    }
    onCancel();
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
  addIssue: PropTypes.func
};
