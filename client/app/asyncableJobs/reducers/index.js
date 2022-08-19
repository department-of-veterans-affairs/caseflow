export const mapDataToInitialState = function(props = {}) {
  const { serverJobs, availableJobs } = props;
  const state = { availableJobs, ...serverJobs };

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
