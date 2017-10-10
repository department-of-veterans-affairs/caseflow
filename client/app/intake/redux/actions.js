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
  return new Promise((resolve, fail) => {
    dispatch({
      type: ACTIONS.FILE_NUMBER_SEARCH_START
    });

    ApiUtil.post('/intake', { data: { file_number: fileNumberSearch } }).
      then(
        (response) => {
          const responseObject = JSON.parse(response.text);

          dispatch({
            type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
            payload: {
              name: responseObject.veteran_name,
              formName: responseObject.veteran_form_name,
              fileNumber: responseObject.veteran_file_number
            }
          });

          resolve();
        },
        (error) => {
          const responseObject = JSON.parse(error.response.text);

          dispatch({
            type: ACTIONS.FILE_NUMBER_SEARCH_FAIL,
            payload: {
              errorCode: responseObject.error_code
            }
          });

          fail();
        }
      );
  });
};
