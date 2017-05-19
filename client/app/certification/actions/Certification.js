import * as Constants from '../constants/constants';

export const showValidationErrors = (erroredFields, scrollToError) => ({
  type: Constants.SHOW_VALIDATION_ERRORS,
  payload: {
    erroredFields,
    scrollToError
  }
});

export const resetState = () => ({
  type: Constants.RESET_STATE
});

export const toggleCancellationModal = () => ({
  type: Constants.TOGGLE_CANCELLATION_MODAL
});
