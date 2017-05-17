import * as Constants from '../constants/constants';

export const showValidationErrors = (erroredFields) => ({
  type: Constants.SHOW_VALIDATION_ERRORS,
  payload: {
    erroredFields
  }
});

export const resetState = () => ({
  type: Constants.RESET_STATE
});

export const toggleCancellationModal = () => ({
  type: Constants.TOGGLE_CANCELLATION_MODAL
});

export const updateErrorNotice = (error) => ({
  type: Constants.UPDATE_ERROR_NOTICE,
  payload: {
    error
  }
});
