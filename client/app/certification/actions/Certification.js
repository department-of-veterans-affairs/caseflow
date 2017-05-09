import * as Constants from '../constants/constants';

export const resetState = () => ({
  type: Constants.RESET_STATE
});

export const toggleCancellationModal = () => ({
  type: Constants.TOGGLE_CANCELLATION_MODAL
});
