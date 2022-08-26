import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

export const sendJobRequest = (jobType) => (dispatch) => {
  dispatch({
    type: ACTIONS.RESET_MANUAL_JOB,
  });

  return ApiUtil.post('asyncable_jobs/start_job', { data: { job_type: jobType } }).
    then((response) => {
      dispatch({
        type: ACTIONS.MANUAL_JOB_STARTED,
        payload: {
          success: response.body.success,
          status: response.status,
          jobType,
        },
      });

      return true;
    },
    (error) => {
      dispatch({
        type: ACTIONS.MANUAL_JOB_FAILED,
        payload: {
          success: response.body.success,
          status: error.status,
          jobType,
        } });

      return true;
    });
};
