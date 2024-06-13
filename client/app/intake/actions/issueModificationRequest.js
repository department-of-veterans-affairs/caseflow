import { ACTIONS } from '../constants';

export const toggleRequestIssueModificationModal = (index) => ({
  type: ACTIONS.TOGGLE_REQUEST_ISSUE_MODIFICATION_MODAL,
  payload: { index }
});

export const toggleRequestIssueRemovalModal = (index) => ({
  type: ACTIONS.TOGGLE_REQUEST_ISSUE_REMOVAL_MODAL,
  payload: { index }
});

export const toggleRequestIssueWithdrawalModal = (index) => ({
  type: ACTIONS.TOGGLE_REQUEST_ISSUE_WITHDRAWAL_MODAL,
  payload: { index }
});

export const toggleRequestIssueAdditionModal = () => ({
  type: ACTIONS.TOGGLE_REQUEST_ISSUE_ADDITION_MODAL
});

export const toggleCancelPendingRequestIssueModal = () => ({
  type: ACTIONS.TOGGLE_CANCEL_PENDING_REQUEST_ISSUE_MODAL
});

export const toggleConfirmPendingRequestIssueModal = () => ({
  type: ACTIONS.TOGGLE_CONFIRM_PENDING_REQUEST_ISSUE_MODAL
});

export const moveToPendingReviewSection = (index, issueModificationRequest) => (
  {
    type: ACTIONS.MOVE_TO_PENDING_REVIEW,
    payload: { index, issueModificationRequest }
  });

export const addToPendingReviewSection = (issueModificationRequest) => (
  {
    type: ACTIONS.ADD_TO_PENDING_REVIEW,
    payload: { issueModificationRequest }
  }
);

export const removeFromPendingReviewSection = (index, issueModificationRequest = null) => (
  {
    type: ACTIONS.REMOVE_FROM_PENDING_REVIEW,
    payload: { index, issueModificationRequest }
  }
);

export const updatePendingReview = (identifier, data) => (
  {
    type: ACTIONS.UPDATE_PENDING_REVIEW,
    payload: { identifier, data }
  }
);
