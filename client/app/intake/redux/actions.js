import { ACTIONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';

export const startNewIntake = () => ({
  type: ACTIONS.START_NEW_INTAKE
});

export const setFileNumberSearch = (fileNumber) => ({
  type: ACTIONS.SET_FILE_NUMBER_SEARCH,
  payload: {
    fileNumber
  }
});

export const doFileNumberSearch = (fileNumberSearch) => (dispatch) => {
  dispatch({
    type: ACTIONS.FILE_NUMBER_SEARCH_START
  });

  return ApiUtil.post('/intake', { data: { file_number: fileNumberSearch } }).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
          payload: {
            intakeId: responseObject.id,
            name: responseObject.veteran_name,
            formName: responseObject.veteran_form_name,
            fileNumber: responseObject.veteran_file_number
          }
        });
      },
      (error) => {
        const responseObject = JSON.parse(error.response.text);

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_FAIL,
          payload: {
            errorCode: responseObject.error_code
          }
        });
      }
    );
};

export const setSelectedOption = (optionSelected) => ({
  type: ACTIONS.SET_SELECTED_OPTION,
  payload: {
    optionSelected
  }
});

export const setReceiptDate = (receiptDate) => ({
  type: ACTIONS.SET_RECEIPT_DATE,
  payload: {
    receiptDate
  }
});

export const submitReview = (rampElection, dispatch) => () => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START
  });

  const data = {
    option_selected: rampElection.optionSelected,
    receipt_date: rampElection.receiptDate
  };

  return ApiUtil.patch(`/intake/ramp/${rampElection.intakeId}`, { data }).
    then(
      () => dispatch({ type: ACTIONS.SUBMIT_REVIEW_SUCCEED }),
      () => dispatch({ type: ACTIONS.SUBMIT_REVIEW_FAIL })
    );
};
