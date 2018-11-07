import { ACTIONS } from '../constants';
import { issueById } from '../util/issues';

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
  type: ACTIONS.TOGGLE_ISSUE_REMOVE_MODAL
});

export const removeIssue = (index) => ({
  type: ACTIONS.REMOVE_ISSUE,
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

export const addRatingRequestIssue = (args) => (dispatch) => {
  const currentIssue = issueById(args.ratings, args.issueId);

  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      id: args.issueId,
      isRating: args.isRating,
      titleOfActiveReview: currentIssue.title_of_active_review,
      timely: currentIssue.timely,
      sourceHigherLevelReview: currentIssue.source_higher_level_review,
      rampClaimId: currentIssue.ramp_claim_id,
      promulgationDate: currentIssue.promulgation_date,
      profileDate: currentIssue.profile_date,
      notes: args.notes,
      untimelyExemption: args.untimelyExemption,
      untimelyExemptionNotes: args.untimelyExemptionNotes
    }
  });
};

export const addNonratingRequestIssue = (args) => (dispatch) => {
  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      category: args.category,
      description: args.description,
      decisionDate: args.decisionDate,
      timely: args.timely,
      untimelyExemption: args.untimelyExemption,
      untimelyExemptionNotes: args.untimelyExemptionNotes,
      isRating: false
    }
  });
};
