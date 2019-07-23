import { ACTIONS } from '../constants';
import { issueByIndex } from '../util/issues';

const analytics = true;

export const toggleAddIssuesModal = () => ({
  type: ACTIONS.TOGGLE_ADD_ISSUES_MODAL,
  meta: { analytics }
});

export const toggleNonratingRequestIssueModal = () => ({
  type: ACTIONS.TOGGLE_NONRATING_REQUEST_ISSUE_MODAL,
  meta: { analytics }
});

export const toggleUnidentifiedIssuesModal = () => ({
  type: ACTIONS.TOGGLE_UNIDENTIFIED_ISSUES_MODAL
});

export const toggleUntimelyExemptionModal = (currentIssueAndNotes = {}) => ({
  type: ACTIONS.TOGGLE_UNTIMELY_EXEMPTION_MODAL,
  payload: { currentIssueAndNotes }
});

export const toggleIssueRemoveModal = () => ({
  type: ACTIONS.TOGGLE_ISSUE_REMOVE_MODAL,
  payload: { index }
});

export const toggleCorrectionTypeModal = () => ({
  type: ACTIONS.TOGGLE_CORRECTION_TYPE_MODAL
});

export const toggleLegacyOptInModal = (currentIssueAndNotes = {}) => ({
  type: ACTIONS.TOGGLE_LEGACY_OPT_IN_MODAL,
  payload: { currentIssueAndNotes }
});

export const removeIssue = (index) => ({
  type: ACTIONS.REMOVE_ISSUE,
  payload: { index }
});

export const withdrawIssue = (index) => ({
  type: ACTIONS.WITHDRAW_ISSUE,
  payload: { index }
});

export const setIssueWithdrawalDate = (withdrawalDate) => ({
  type: ACTIONS.SET_ISSUE_WITHDRAWAL_DATE,
  payload: { withdrawalDate }
});

export const correctIssue = ({index, correctionType}) => ({
  type: ACTIONS.CORRECT_ISSUE,
  payload: { index, correctionType }
});

export const undoCorrection = (index) => ({
  type: ACTIONS.UNDO_CORRECTION,
  payload: { index }
});

export const addUnidentifiedIssue = (description, notes) => (dispatch) => {
  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      isUnidentified: true,
      description,
      notes
    }
  });
};

export const setEditContentionText = (issueIdx, editedDescription) => ({
  type: ACTIONS.SET_EDIT_CONTENTION_TEXT,
  payload: {
    issueIdx,
    editedDescription
  }
});

export const addRatingRequestIssue = (args) => (dispatch) => {
  const currentIssue = issueByIndex(args.contestableIssues, args.contestableIssueIndex);

  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      index: args.contestableIssueIndex,
      isRating: args.isRating,
      ratingIssueReferenceId: currentIssue.ratingIssueReferenceId,
      ratingIssueProfileDate: currentIssue.ratingIssueProfileDate,
      ratingIssueDiagnosticCode: currentIssue.ratingIssueDiagnosticCode,
      decisionIssueId: currentIssue.decisionIssueId,
      titleOfActiveReview: currentIssue.titleOfActiveReview,
      description: currentIssue.description,
      timely: currentIssue.timely,
      sourceReviewType: currentIssue.sourceReviewType,
      rampClaimId: currentIssue.rampClaimId,
      decisionDate: currentIssue.approxDecisionDate,
      notes: args.notes,
      untimelyExemption: args.untimelyExemption,
      untimelyExemptionNotes: args.untimelyExemptionNotes,
      vacolsId: args.vacolsId,
      vacolsSequenceId: args.vacolsSequenceId,
      eligibleForSocOptIn: args.eligibleForSocOptIn
    }
  });
};

export const addNonratingRequestIssue = (args) => (dispatch) => {
  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      benefitType: args.benefitType,
      category: args.category,
      description: args.description,
      decisionDate: args.decisionDate,
      timely: args.timely,
      untimelyExemption: args.untimelyExemption,
      untimelyExemptionNotes: args.untimelyExemptionNotes,
      isRating: false,
      vacolsId: args.vacolsId,
      vacolsSequenceId: args.vacolsSequenceId,
      eligibleForSocOptIn: args.eligibleForSocOptIn,
      ineligibleDueToId: args.ineligibleDueToId,
      ineligibleReason: args.ineligibleReason,
      decisionReviewTitle: args.decisionReviewTitle
    }
  });
};
