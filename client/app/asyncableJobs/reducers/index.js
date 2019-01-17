export const mapDataToInitialState = function(props = {}) {
  const { serverJobs } = props;

  let state = serverJobs;

  if (!state.asyncable_job_klass) {
    state.asyncableJobsKlass = 'All Jobs';
  }

  return state;
};

export const asyncableJobsReducer = (state = mapDataToInitialState(), action) => {
  console.log(action);
  switch (action.type) {
  case "foobar":
    return update(state, { currentTab: { $set: action.payload.currentTab } });
  default:
    return state;
  }
};
