import * as Constants from '../constants/constants';

export const onContinueClickFailed = () => ({
  type: Constants.ON_CONTINUE_CLICK_FAILED,
  payload: {
    continueClicked: true
  }
});

export const onContinueClickSuccess = () => ({
  type: Constants.ON_CONTINUE_CLICK_SUCCESS,
  payload: {
    continueClicked: false
  }
});

export const resetState = () => ({
  type: Constants.RESET_STATE
});

export const toggleCancellationModal = () => ({
  type: Constants.TOGGLE_CANCELLATION_MODAL
});

export const toggleHeader = () => ({
  type: Constants.TOGGLE_HEADER
});
