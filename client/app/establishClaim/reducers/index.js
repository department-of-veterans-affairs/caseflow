import * as Constants from '../constants';
import update from 'immutability-helper';

export const getEstablishClaimInitialState = function() {
  return {
    cancelFeedback: '',
    isSubmittingCancelFeedback: false,
    isShowingCancelModal: false,
    isValidating: false,
    loading: false,
    error: false
  };
};

export const establishClaim = function(state = getEstablishClaimInitialState(), action) {
  switch (action.type) {
  case Constants.REQUEST_CANCEL_FEEDBACK:
    return {
      ...state,
      isSubmittingCancelFeedback: true
    };
  case Constants.REQUEST_CANCEL_FEEDBACK_FAILURE:
    return {
      ...state,
      isShowingCancelModal: false,
      isSubmittingCancelFeedback: false,
      isValidating: false
    };
  case Constants.VALIDATE_CANCEL_FEEDBACK:
    return {
      ...state,
      isValidating: true
    };
  case Constants.TOGGLE_CANCEL_TASK_MODAL:
    return {
      ...state,
      isValidating: false,
      isShowingCancelModal: !state.isShowingCancelModal
    };
  case Constants.TRIGGER_LOADING:
    return update(state, {
      loading: {
        $set: action.payload.value
      }
    });
  case Constants.CHANGE_CANCEL_FEEDBACK:
    return {
      ...state,
      isValidating: false,
      cancelFeedback: action.payload.value
    };
  case Constants.SHOW_SPECIAL_ISSUE_ERROR: {
    return {
      ...state,
      error: true
    };
  }
  case Constants.CLEAR_SPECIAL_ISSUE_ERROR: {
    return {
      ...state,
      error: false
    };
  }
  default:
    return state;
  }
};

export default establishClaim;
