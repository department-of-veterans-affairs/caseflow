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