import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

export const sendJobRequest = (jobType, runAsync) => (dispatch) => {
  dispatch({
    type: ACTIONS.CLEAR_MANUAL_JOB_TYPE,
  });

  return ApiUtil.post('asyncable_jobs/start_job', { data: { job_type: jobType, run_async: runAsync } }).
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
