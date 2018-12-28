import { formatTasks } from '../util';

export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  return {
    businessLine: serverNonComp.businessLine,
    inProgressTasks: formatTasks(serverNonComp.inProgressTasks),
    completedTasks: formatTasks(serverNonComp.completedTasks),
    selectedTask: null
  };
};

export const nonCompReducer = (state = mapDataToInitialState()) => {
  return state;
};
