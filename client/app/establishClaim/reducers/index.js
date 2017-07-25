import * as Constants from '../constants';

export const getEstablishClaimInitialState = function() {
  return {
    cancelFeedback: '',
    isSubmittingCancelFeedback: false,
    isShowingCancelModal: false,
    isValidating: false,
    loading: false
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
    return {
      ...state,
      loading: action.payload.value
    };
  case Constants.CHANGE_CANCEL_FEEDBACK:
    return {
      ...state,
      isValidating: false,
      cancelFeedback: action.payload.value
    };
  default:
    return state;
  }
};

export default establishClaim;
