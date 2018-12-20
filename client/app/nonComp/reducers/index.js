export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  return {
    businessLine: serverNonComp.businessLine,
    inProgressTasks: serverNonComp.inProgressTasks,
    completedTasks: serverNonComp.completedTasks,
    selectedTask: null
  };
};

export const nonCompReducer = (state = mapDataToInitialState()) => {
  return state;
};
