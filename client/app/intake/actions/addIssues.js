import { ACTIONS } from '../constants';
import { issueByIndex } from '../util/issues';

const analytics = true;

export const toggleAddingIssue = () => ({
  type: ACTIONS.TOGGLE_ADDING_ISSUE,
  meta: { analytics }
});

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

export const toggleIssueRemoveModal = (index) => ({
  type: ACTIONS.TOGGLE_ISSUE_REMOVE_MODAL,
  payload: { index }
});

export const toggleCorrectionTypeModal = ({ index, isNewIssue } = {}) => ({
  type: ACTIONS.TOGGLE_CORRECTION_TYPE_MODAL,
  payload: { index,
    isNewIssue }
});

export const toggleLegacyOptInModal = (currentIssueAndNotes = {}) => ({
  type: ACTIONS.TOGGLE_LEGACY_OPT_IN_MODAL,
  payload: { currentIssueAndNotes }
});

export const toggleEditIntakeIssueModal = (index) => ({
  type: ACTIONS.TOGGLE_EDIT_INTAKE_ISSUES_MODAL,
  payload: { index }
});

export const setMstPactDetails = (editIssuesDetails) => ({
  type: ACTIONS.SET_MST_PACT_DETAILS,
  payload: { editIssuesDetails }
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

export const correctIssue = ({ index, correctionType }) => ({
  type: ACTIONS.CORRECT_ISSUE,
  payload: { index,
    correctionType }
});

export const undoCorrection = (index) => ({
  type: ACTIONS.UNDO_CORRECTION,
  payload: { index }
});

export const setEditContentionText = (issueIdx, editedDescription) => ({
  type: ACTIONS.SET_EDIT_CONTENTION_TEXT,
  payload: {
    issueIdx,
    editedDescription
  }
});

export const addIssue = (currentIssue) => (dispatch) => {
  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      ...currentIssue,
      editable: true
    }
  });
};

export const addContestableIssue = (args) => (dispatch) => {
  const currentIssue = args.currentIssue || issueByIndex(args.contestableIssues, args.contestableIssueIndex);

  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      index: args.contestableIssueIndex,
      isRating: args.isRating,
      ratingIssueReferenceId: currentIssue.ratingIssueReferenceId,
      ratingDecisionReferenceId: currentIssue.ratingDecisionReferenceId,
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
      eligibleForSocOptIn: args.eligibleForSocOptIn,
      eligibleForSocOptInWithExemption: args.eligibleForSocOptInWithExemption,
      correctionType: args.correctionType,
      editable: true
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
      eligibleForSocOptInWithExemption: args.eligibleForSocOptInWithExemption,
      ineligibleDueToId: args.ineligibleDueToId,
      ineligibleReason: args.ineligibleReason,
      decisionReviewTitle: args.decisionReviewTitle,
      correctionType: args.correctionType,
      editable: true
    }
  });
};
