import * as Constants from '../constants/constants';

export const changeErroredFields = (erroredFields) => ({
  type: Constants.CHANGE_ERRORED_FIELDS,
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
