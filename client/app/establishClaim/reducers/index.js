import * as Constants from '../constants';

export const getEstablishClaimInitialState = function(props = {}) {
  return {
    cancelFeedback: '',
    isCancelModalSubmitting: false,
    isShowingCancelModal: false
  };
};

export const establishClaim = function(state = getEstablishClaimInitialState(), action) {
  switch (action.type) {
  case Constants.TOGGLE_CANCEL_TASK_MODAL:
    return {
      ...state,
      isShowingCancelModal: !state.isShowingCancelModal
    };
  default:
    return state;
  }
};

export default establishClaim;
