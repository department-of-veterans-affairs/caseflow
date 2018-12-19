export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  return {
    businessLine: serverNonComp.businessLine,
    unassignedTasks: serverNonComp.unassignedTasks,
    completedTasks: serverNonComp.completedTasks,
    selectedTask: null
  };
};

export const nonCompReducer = (state = mapDataToInitialState(), action) => {
  return state;
};
