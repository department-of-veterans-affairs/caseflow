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
  let foundDate = _.filter(args.ratings, (ratingDate) => _.some(ratingDate.issues, { reference_id: args.issueId }));

  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      id: args.issueId,
      isRated: args.isRated,
      inActiveReview: foundDate[0].issues[args.issueId].in_active_review,
      timely: foundDate[0].issues[args.issueId].timely,
      promulgationDate: foundDate[0].issues[args.issueId].promulgation_date,
      profileDate: foundDate[0].profile_date,
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
