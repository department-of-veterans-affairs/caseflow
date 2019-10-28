import { combineReducers } from 'redux';

const initialState = {
  submitting: false,
  error: null
};

const attorneyView = (state = { ...initialState }, action) => {
  switch (action.type) {
  case 'MTV_SUBMIT_ATTY_REVIEW':
    return {
      ...state,
      submitting: true
    };
  case 'MTV_SUBMIT_ATTY_REVIEW_ERROR':
    return {
      ...state,
      submitting: false,
      error: action.payload
    };
  case 'MTV_SUBMIT_ATTY_REVIEW_SUCCESS':
    return {
      ...state,
      submitting: false
    };
  default:
    return state;
  }
};

const judgeView = (state = { ...initialState }, action) => {
  switch (action.type) {
  case 'MTV_SUBMIT_JUDGE_DECISION':
    return {
      ...state,
      submitting: true
    };
  case 'MTV_SUBMIT_JUDGE_DECISION_ERROR':
    return {
      ...state,
      submitting: false,
      error: action.payload
    };
  case 'MTV_SUBMIT_JUDGE_DECISION_SUCCESS':
    return {
      ...state,
      submitting: false
    };
  default:
    return state;
  }
};

export default combineReducers({ attorneyView,
  judgeView });
