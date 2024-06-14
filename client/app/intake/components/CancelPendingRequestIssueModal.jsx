import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import { formatDateStr } from 'app/util/DateUtil';
import { capitalize } from 'lodash';
import COPY from '../../../COPY';

export const CancelPendingRequestIssueModal = (props) => {

  const {
    pendingIssueModificationRequest,
    onCancel,
    removeFromPendingReviewSection,
    toggleCancelPendingRequestIssueModal
  } = props;

  const requestIssue = pendingIssueModificationRequest.requestIssue;

  const withdrawalDate = (
    <div>
      <strong>Request date for withdrawal: </strong>{formatDateStr(pendingIssueModificationRequest?.withdrawalDate)}
    </div>
  );

  const requestReason = (
    <div>
      <strong> {capitalize(pendingIssueModificationRequest.requestType)} request reason:</strong>
      {pendingIssueModificationRequest.requestReason}
    </div>
  );

  const baseIssueInformation = (
    <div>
      <h2 style={{ marginBottom: '0px' }}>Pending issue request</h2>
      <strong>Issue type: </strong>{pendingIssueModificationRequest.nonratingIssueCategory}<br />
      <strong>Decision date: </strong>{formatDateStr(pendingIssueModificationRequest.decisionDate)}<br />
      <strong>Issue description: </strong>{pendingIssueModificationRequest.nonratingIssueDescription ||
        pendingIssueModificationRequest.nonRatingIssueDescription}<br />
    </div>
  );

  const originalIssue = (
    <div>
      <h2 style={{ marginBottom: '0px' }}>Current issue</h2>
      <strong>Issue type: </strong>{requestIssue?.nonratingIssueCategory || requestIssue?.category}<br />
      <strong>Decision date: </strong>{formatDateStr(requestIssue?.decisionDate)}<br />
      <strong>Issue description: </strong>{requestIssue?.nonratingIssueDescription ||
      requestIssue?.nonRatingIssueDescription}<br />
    </div>
  );

  const modalInfo = {
    [COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE]: (
      <div>
        {baseIssueInformation}
        {requestReason}
      </div>
    ),
    [COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE]: (
      <div>
        {originalIssue}
        <br />
        {baseIssueInformation}
        {requestReason}
      </div>
    ),
    [COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE]: (
      <div>
        {baseIssueInformation}
        {requestReason}
      </div>
    ),
    [COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE]: (
      <div>
        {baseIssueInformation}
        {withdrawalDate}
        {requestReason}
      </div>
    )
  };

  const handleSubmit = () => {
    removeFromPendingReviewSection(pendingIssueModificationRequest);
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
      {modalInfo[pendingIssueModificationRequest.requestType]}
    </Modal>
  );
};

CancelPendingRequestIssueModal.propTypes = {
  pendingIssueModificationRequest: PropTypes.object,
  onCancel: PropTypes.func,
  removeFromPendingReviewSection: PropTypes.func,
  toggleCancelPendingRequestIssueModal: PropTypes.func
};
