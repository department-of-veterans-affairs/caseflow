import _ from 'lodash';
import { ACTIONS } from '../constants';

const analytics = true;

export const toggleAddIssuesModal = () => ({
  type: ACTIONS.TOGGLE_ADD_ISSUES_MODAL,
  meta: { analytics }
});

export const toggleNonRatedIssueModal = () => ({
  type: ACTIONS.TOGGLE_NON_RATED_ISSUE_MODAL,
  meta: { analytics }
});

export const toggleUnidentifiedIssuesModal = () => ({
  type: ACTIONS.TOGGLE_UNIDENTIFIED_ISSUES_MODAL
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

export const addRatedIssue = (args) => (dispatch) => {
  let currentRating = _.filter(
    args.ratings,
    (ratingDate) => _.some(ratingDate.issues, { reference_id: args.issueId })
  )[0];
  let currentIssue = currentRating.issues[args.issueId];

  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      id: args.issueId,
      isRated: args.isRated,
      activeReviewOfDuplicateIssue: currentIssue.active_review_of_duplicate_issue,
      timely: currentIssue.timely,
      sourceHigherLevelReview: currentIssue.source_higher_level_review,
      promulgationDate: currentIssue.promulgation_date,
      profileDate: currentRating.profile_date,
      notes: args.notes
    }
  });
};

export const addNonRatedIssue = (category, description, decisionDate, isRated = false) => (dispatch) => {
  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      category,
      description,
      decisionDate,
      isRated
    }
  });
};
