export const mapDataToInitialState = function(props = {}) {
  const { serverJobs } = props;

  let state = serverJobs;

  if (!state.asyncableJobKlass) {
    state.asyncableJobKlass = 'All';
  }

  return state;
};

export const asyncableJobsReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  default:
    return state;
  }
};
