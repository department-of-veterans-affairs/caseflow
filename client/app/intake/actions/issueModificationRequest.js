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

export const toggleConfirmPendingRequestIssueModal = (data) => ({
  type: ACTIONS.TOGGLE_CONFIRM_PENDING_REQUEST_ISSUE_MODAL,
  payload: { data }
});

export const updatePendingReview = (identifier, data) => (
  {
    type: ACTIONS.UPDATE_PENDING_REVIEW,
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

export const issueWithdrawalRequestApproved = (identifier, issueModificationRequest) => (
  {
    type: ACTIONS.ISSUE_WITHDRAW_REQUEST_APPROVED,
    payload: { identifier, issueModificationRequest }
  }
);

export const cancelOrRemovePendingReview = (issueModificationRequest) => (
  {
    type: ACTIONS.CANCEL_OR_REMOVE_PENDING_REVIEW,
    payload: { issueModificationRequest }
  }
);

export const issueAdditionRequestApproved = (issueModificationRequest) => (
  {
    type: ACTIONS.ISSUE_ADDITION_REQUEST_APPROVED,
    payload: { issueModificationRequest }
  }
);

export const updateActiveIssueModificationRequest = (data) => (
  {
    type: ACTIONS.ACTIVE_ISSUE_MODIFICATION_REQUEST,
    payload: { data }
  }
);

export const setAllApprovedIssueModificationsWithdrawalDates = (withdrawalDate) => (
  {
    type: ACTIONS.SET_ALL_APPROVED_ISSUE_MODIFICATION_WITHDRAWAL_DATES,
    payload: { withdrawalDate }
  }
);
