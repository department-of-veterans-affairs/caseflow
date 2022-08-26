import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

export const sendJobRequest = (jobType) => (dispatch) => {
  return ApiUtil.post('api/v1/jobs', { data: { job_type: jobType, perform_now: true } }).
    then((response) => {
      dispatch({
        type: ACTIONS.MANUAL_JOB_STARTED,
        payload: {
          success: response.response.success,
          job_id: response.response.job_id,
          status: response.status,
        },
      });

      return true;
    },
    (error) => {
      dispatch({
        type: ACTIONS.MANUAL_JOB_FAILED,
        payload: {
          success: error.response.success,
          job_id: error.response.job_id,
          status: error.status,
        } });

      return true;
    });
};
