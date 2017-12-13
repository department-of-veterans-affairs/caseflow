import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';

const analytics = true;

export const startNewIntake = () => ({
  type: ACTIONS.START_NEW_INTAKE,
  meta: { analytics }
});

export const setFileNumberSearch = (fileNumber) => ({
  type: ACTIONS.SET_FILE_NUMBER_SEARCH,
  payload: {
    fileNumber
  }
});

export const doFileNumberSearch = (formType, fileNumberSearch) => (dispatch) => {
  dispatch({
    type: ACTIONS.FILE_NUMBER_SEARCH_START,
    meta: { analytics }
  });

  const data = { file_number: fileNumberSearch,
    form_type: formType };

  return ApiUtil.post('/intake', { data }, ENDPOINT_NAMES.INTAKE).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });
      },
      (error) => {
        const responseObject = JSON.parse(error.response.text);
        const errorCode = responseObject.error_code;

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_FAIL,
          payload: {
            errorCode,
            errorData: responseObject.error_data || {}
          },
          meta: {
            analytics: {
              label: errorCode
            }
          }
        });

        throw error;
      }
    );
};

export const setFormType = (formType) => ({
  type: ACTIONS.SET_FORM_TYPE,
  payload: {
    formType
  },
  meta: {
    analytics: {
      label: formType
    }
  }
});

export const toggleCancelModal = () => ({
  type: ACTIONS.TOGGLE_CANCEL_MODAL,
  meta: {
    analytics: {
      label: (nextState) => nextState.cancelModalVisible ? 'show' : 'hide'
    }
  }
});

export const submitCancel = (intakeId) => (dispatch) => {
  dispatch({
    type: ACTIONS.CANCEL_INTAKE_START,
    meta: { analytics }
  });

  return ApiUtil.delete(`/intake/${intakeId}`, {}, ENDPOINT_NAMES.INTAKE_RAMP).
    then(
      () => dispatch({
        type: ACTIONS.CANCEL_INTAKE_SUCCEED,
        meta: { analytics }
      }),
      (error) => {
        dispatch({
          type: ACTIONS.CANCEL_INTAKE_FAIL,
          meta: { analytics }
        });
        throw error;
      }
    );
};
