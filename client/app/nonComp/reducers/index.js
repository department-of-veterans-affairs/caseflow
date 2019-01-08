import { formatTasks } from '../util';
import { ACTIONS } from '../constants';

export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  let state = serverNonComp;

  state.inProgressTasks = formatTasks(serverNonComp.inProgressTasks);
  state.completedTasks = formatTasks(serverNonComp.completedTasks);
  state.selectedTask = null;
  state.decisionIssuesStatus = {};

  return state;
};

export const nonCompReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_START:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: 'IN_PROGRESS'
        }
      }
    });
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: 'SUCCEED'
        },
        errorCode: { $set: null}
      }
    });
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_FAIL:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: 'FAIL'
        },
        errorCode: { $set: action.payload.responseErrorCode}
      }
    });
  }
  return state;
};
