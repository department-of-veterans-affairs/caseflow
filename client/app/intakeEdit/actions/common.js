import { ACTIONS, ENDPOINT_NAMES } from '../../intake/constants';
import ApiUtil from '../../util/ApiUtil';

const analytics = true;

export const saveIntakeEdit = (intakeId, intakeData) => (dispatch) =>{
  dispatch({
    type: ACTIONS.SAVE_INTAKE_EDIT_START,
    meta: { analytics }
  });

  const data = formatIssues(intakeData);

  return ApiUtil.patch(`/${reviewType}/${reviewId}/save`, { data }, ENDPOINT_NAMES.COMPLETE_INTAKE).
  return ApiUtil.patch(`/intake/${intakeId}/complete`, { data }, ENDPOINT_NAMES.COMPLETE_INTAKE).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        let responseObject = {};

        try {
          responseObject = JSON.parse(error.response.text);
        } catch (ex) { /* pass */ }

        const responseErrorCode = responseObject.error_code;
        const responseErrorData = responseObject.error_data;

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_FAIL,
          payload: {
            responseErrorCode,
            responseErrorData
          },
          meta: { analytics }
        });
        throw error;
      }
    );
};
