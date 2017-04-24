import * as Constants from '../constants/constants';

export const onValidationFailed = (invalidFields) => ({
  type: Constants.ON_VALIDATION_FAILED,
  payload: {
    validationFailed: true,
    invalidFields
  }
});

export const onValidationSuccess = () => ({
  type: Constants.ON_VALIDATION_SUCCESS,
  payload: {
    validationFailed: false
  }
});

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