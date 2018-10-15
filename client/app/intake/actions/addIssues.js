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

export const addRatedIssue = (id, ratings, isRated, notes) => (dispatch) => {
  let foundDate = _.filter(ratings, (ratingDate) => _.some(ratingDate.issues, { reference_id: id }));

  dispatch({
    type: ACTIONS.ADD_ISSUE,
    payload: {
      id,
      isRated,
      profileDate: foundDate[0].profile_date,
      notes
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
