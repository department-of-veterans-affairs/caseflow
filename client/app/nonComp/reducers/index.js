import { formatTasks } from '../util';

export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  let state = serverNonComp;

  state.inProgressTasks = formatTasks(serverNonComp.inProgressTasks);
  state.completedTasks = formatTasks(serverNonComp.completedTasks);
  state.selectedTask = null;

  return state;
};

export const nonCompReducer = (state = mapDataToInitialState()) => {
  return state;
};
