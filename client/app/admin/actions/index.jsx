import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

export const setFeatureToggles = (featureToggles) => ({
  type: ACTIONS.SET_FEATURE_TOGGLES,
  payload: { featureToggles }
});

export const sendExtractRequest = () => (dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_VETERAN_EXTRACT,
  });

  return ApiUtil.get('admin/veteran_extract').
    then((response) => {
      dispatch({
        type: ACTIONS.POST_VETERAN_EXTRACT,
        payload: {
          success: response.body.success,
          status: response.status,
          contents: response.body.contents,
          message: response.body.message,
        },
      });
    },
    (error) => {
      dispatch({
        type: ACTIONS.FAILED_VETERAN_EXTRACT,
        payload: {
          success: error.body.success,
          status: error.status,
          err: error
        } });
    });
};
