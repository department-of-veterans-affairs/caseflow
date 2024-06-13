import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import { formatDateStr } from '../../util/DateUtil';
import COPY from '../../../COPY';
import { convertPendingIssueToRequestIssue } from '../util/issueModificationRequests';
import { addIssue, removeIssue } from '../actions/addIssues';
import {
  updatePendingReview,
  toggleConfirmPendingRequestIssueModal
} from '../actions/issueModificationRequest';

export const ConfirmPendingRequestIssueModal = (props) => {

  const {
    pendingIssueModificationRequest,
  } = props;

  const enhancedPendingIssueModification = useSelector((state) => state.enhancedPendingIssueModification.
    find((issue) => issue.id === pendingIssueModificationRequest.id));

  // is this right way to find this
  // const modifiedPendingModificationRequest = enhancedPendingIssueModification?.
  //   find((pi) => pi.id === pendingIssueModificationRequest.id);

  const requestIssue = pendingIssueModificationRequest.requestIssue;
  const indexOfOriginalIssue = useSelector(
    (state) => state.addedIssues.findIndex((issue) => issue.id === enhancedPendingIssueModification.requestIssue.id));

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
      <strong>Issue type: </strong>{enhancedPendingIssueModification?.nonratingIssueCategory}<br />
      <strong>Decision date: </strong>{formatDateStr(enhancedPendingIssueModification?.decisionDate)}<br />
      <strong>Issue description: </strong>{enhancedPendingIssueModification?.nonratingIssueDescription}<br />
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
    const newRequestIssue = convertPendingIssueToRequestIssue(enhancedPendingIssueModification);

    // Remove the original issue from addedIssues
    dispatch(removeIssue(indexOfOriginalIssue));
    // Add the pending issue that is now a request issue to addedIssues
    dispatch(addIssue(newRequestIssue));
    // Update the pending issue status
    dispatch(updatePendingReview(enhancedPendingIssueModification.identifier,
      { status: enhancedPendingIssueModification.status }));
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
      {modalInfo[pendingIssueModificationRequest.requestType]}
    </Modal>
  );
};

ConfirmPendingRequestIssueModal.propTypes = {
  pendingIssueModificationRequest: PropTypes.object,
};
