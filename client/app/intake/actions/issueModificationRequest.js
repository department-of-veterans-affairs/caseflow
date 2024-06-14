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

export const updatePendingReview = (identifier, data) => (
  {
    type: ACTIONS.UPDATE_PENDING_REVIEW,
    payload: { identifier, data }
  }
);

export const enhancedPendingReview = (identifier, data) => (
  {
    type: ACTIONS.ENHANCED_PENDING_REVIEW,
    payload: { identifier, data }
  }
);

export const moveToPendingReviewSection = (issueModificationRequest) => (
  {
    type: ACTIONS.MOVE_TO_PENDING_REVIEW,
    payload: { issueModificationRequest }
  });

export const addToPendingReviewSection = (issueModificationRequest) => (
  {
    type: ACTIONS.ADD_TO_PENDING_REVIEW,
    payload: { issueModificationRequest }
  }
);

export const removeFromPendingReviewSection = (index) => (
  {
    type: ACTIONS.REMOVE_FROM_PENDING_REVIEW,
    payload: { index }
  }
);

export const adminWithdrawRequestIssue = (identifier, issueModificationRequest) => (
  {
    type: ACTIONS.ADMIN_WITHDRAW_REQUESTED_ISSUE,
    payload: { identifier, issueModificationRequest }
  }
);

export const adminRemoveRequestIssue = (identifier, issueModificationRequest) => (
  {
    type: ACTIONS.ADMIN_REMOVE_REQUESTED_ISSUE,
    payload: { identifier, issueModificationRequest }
  }
);

export const adminAddRequestIssue = (issueModificationRequest) => (
  {
    type: ACTIONS.ADMIN_ADD_REQUESTED_ISSUE,
    payload: { issueModificationRequest }
  }
);

export const adminModifyRequestIssueKeepOriginal = (issueModificationRequest) => (
  {
    type: ACTIONS.ADMIN_MODIFY_REQUESTED_ISSUE_KEEP_ORIGINAL,
    payload: { issueModificationRequest }
  }
);
