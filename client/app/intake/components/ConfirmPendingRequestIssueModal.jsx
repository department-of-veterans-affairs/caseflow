import React from 'react';
import { useSelector } from 'react-redux';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import { formatDateStr } from '../../util/DateUtil';
import COPY from '../../../COPY';
import { convertPendingIssueToRequestIssue } from '../util/issueModificationRequests';

export const ConfirmPendingRequestIssueModal = (props) => {

  const {
    pendingIssueModificationRequest,
    toggleConfirmPendingRequestIssueModal,
    addIssue,
    removeIssue,
    removeFromPendingReviewSection
  } = props;

  const requestIssue = pendingIssueModificationRequest.requestIssue;
  const indexOfOriginalIssue = useSelector(
    (state) => state.addedIssues.findIndex((issue) => issue.id === pendingIssueModificationRequest.requestIssue.id));

  const originalIssue = (
    <div>
      <h2 style={{ marginBottom: '0px' }}>Delete original issue</h2>
      <strong>Issue type: </strong>{requestIssue?.nonratingIssueCategory || requestIssue?.category}<br />
      <strong>Decision date: </strong>{formatDateStr(requestIssue?.decisionDate)}<br />
      <strong>Issue description: </strong>{requestIssue?.nonratingIssueDescription ||
      requestIssue?.nonRatingIssueDescription}<br />
    </div>
  );

  const newIssue = (
    <div>
      <h2 style={{ marginBottom: '0px' }}>Create new issue</h2>
      <strong>Issue type: </strong>{pendingIssueModificationRequest?.nonratingIssueCategory}<br />
      <strong>Decision date: </strong>{formatDateStr(pendingIssueModificationRequest?.decisionDate)}<br />
      <strong>Issue description: </strong>{pendingIssueModificationRequest?.nonratingIssueDescription}<br />
    </div>
  );

  const modalInfo = {
    [COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE]: (
      <div>
        {originalIssue}
        <br />
        {newIssue}
      </div>
    )
  };

  const onSubmit = () => {
    const newRequestIssue = convertPendingIssueToRequestIssue(pendingIssueModificationRequest);

    // Remove the original issue from addedIssues
    removeIssue(indexOfOriginalIssue);
    // Add the pending issue that is now a request issue to addedIssues
    addIssue(newRequestIssue);
    // Remove the pending issue as it is now a request issue
    removeFromPendingReviewSection(null, pendingIssueModificationRequest);
    toggleConfirmPendingRequestIssueModal();
  };

  return (
    <Modal
      title="Confirm changes"
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
          name: 'Cancel',
          onClick: toggleConfirmPendingRequestIssueModal
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Confirm',
          onClick: () => onSubmit()
        }
      ]}
      closeHandler={toggleConfirmPendingRequestIssueModal}
    >
      {modalInfo[pendingIssueModificationRequest.requestType]}
    </Modal>
  );
};

ConfirmPendingRequestIssueModal.propTypes = {
  pendingIssueModificationRequest: PropTypes.object,
  toggleConfirmPendingRequestIssueModal: PropTypes.func,
  addIssue: PropTypes.func,
  removeIssue: PropTypes.func,
  removeFromPendingReviewSection: PropTypes.func
};
