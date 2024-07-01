import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import Modal from '../../components/Modal';
import { formatDateStr } from '../../util/DateUtil';
import COPY from '../../../COPY';
import { convertPendingIssueToRequestIssue } from '../util/issueModificationRequests';
import { addIssue, removeIssue } from '../actions/addIssues';
import {
  updatePendingReview,
  toggleConfirmPendingRequestIssueModal
} from '../actions/issueModificationRequest';

export const ConfirmPendingRequestIssueModal = () => {
  const activeIssueModificationRequest = useSelector((state) => state.activeIssueModificationRequest);

  const requestIssue = activeIssueModificationRequest.requestIssue;

  const indexOfOriginalIssue = useSelector(
    (state) => state.addedIssues.findIndex((issue) => issue.id === activeIssueModificationRequest.requestIssue.id));

  const dispatch = useDispatch();

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
      <strong>Issue type: </strong>{activeIssueModificationRequest.nonratingIssueCategory}<br />
      <strong>Decision date: </strong>{formatDateStr(activeIssueModificationRequest.decisionDate)}<br />
      <strong>Issue description: </strong>{activeIssueModificationRequest.nonratingIssueDescription}<br />
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
    // Since this is being treated as a brand new request issue. The issue modification request
    // no longer needs to retain references to the old request issue
    const modifiedIssueRequest = { ...activeIssueModificationRequest, requestIssue: {}, requestIssueId: null };

    // Update the pending issues data if any modification was made in the main modal
    // this also updated the status to approved thus removing it from pending section.
    dispatch(updatePendingReview(activeIssueModificationRequest.identifier,
      modifiedIssueRequest));

    const newFormattedRequestIssue = convertPendingIssueToRequestIssue(modifiedIssueRequest);

    dispatch(removeIssue(indexOfOriginalIssue));
    // Add the pending issue that is now a request issue to addedIssues
    dispatch(addIssue(newFormattedRequestIssue));
    // close modal
    dispatch(toggleConfirmPendingRequestIssueModal());
  };

  return (
    <Modal
      title="Confirm changes"
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
          name: 'Cancel',
          onClick: () => dispatch(toggleConfirmPendingRequestIssueModal())
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Confirm',
          onClick: onSubmit
        }
      ]}
      closeHandler={() => dispatch(toggleConfirmPendingRequestIssueModal())}
    >
      {modalInfo[activeIssueModificationRequest.requestType]}
    </Modal>
  );
};
