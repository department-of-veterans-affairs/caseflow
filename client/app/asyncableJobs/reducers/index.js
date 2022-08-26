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
  default:
    return state;
  }
};
