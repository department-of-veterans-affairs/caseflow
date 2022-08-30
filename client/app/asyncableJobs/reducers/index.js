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
  case ACTIONS.CLEAR_MANUAL_JOB_TYPE:
    return { ...state, manualJobType: null };
  case ACTIONS.MANUAL_JOB_STARTED:
    return {
      ...state,
      manualJobStatus: action.payload.status,
      manualJobSuccess: action.payload.success,
      manualJobType: action.payload.jobType,
    };
  case ACTIONS.MANUAL_JOB_FAILED:
    return {
      ...state,
      manualJobStatus: action.payload.status,
      manualJobSuccess: false,
      manualJobType: action.payload.jobType,
    };
  default:
    return state;
  }
};
