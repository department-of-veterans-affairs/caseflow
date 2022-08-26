import { ACTIONS } from '../constants';

export const mapDataToInitialState = function(props = {}) {
  const { serverJobs } = props;
  const state = serverJobs;

  if (!state.asyncableJobKlass) {
    state.asyncableJobKlass = '';
  }

  return state;
};

export const asyncableJobsReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.MANUAL_JOB_STARTED:
    return {
      ...state,
      manualJobStatus: action.payload.status,
      manualJobId: action.payload.job_id,
      manualJobSuccess: action.payload.success
    };
  case ACTIONS.MANUAL_JOB_FAILED:
    return {
      ...state,
      manualJobStatus: action.payload.status,
      manualJobSuccess: false
    };
  default:
    return state;
  }
};
