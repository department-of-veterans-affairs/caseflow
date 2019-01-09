import { formatTasks } from '../util';
import { ACTIONS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { update } from '../../util/ReducerUtil';
import _ from 'lodash';

export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  let state = serverNonComp;
  state.inProgressTasks = formatTasks(serverNonComp.inProgressTasks);
  state.completedTasks = formatTasks(serverNonComp.completedTasks);
  state.selectedTask = null;
  state.decisionIssuesStatus = {};

  console.log("mapDataToInitialState", state.inProgressTasks, state.completedTasks);

  return state;
};

export const nonCompReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_START:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS
        }
      }
    });
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED:
    // update inprogress task to completed
    const completedIndex = _.findIndex(state.inProgressTasks, (item) => item.id === action.payload.completedTaskId);
    let updatedInProgressTasks = state.inProgressTasks;
    let updatedCompletedTasks = state.completedTasks;

    if (completedIndex != -1) {
      updatedInProgressTasks = [
        ...state.inProgressTasks.slice(0, completedIndex),
        ...state.inProgressTasks.slice(completedIndex + 1)];

      updatedCompletedTasks = [state.inProgressTasks[completedIndex]].concat(updatedCompletedTasks);
    }

    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.SUCCEED
        },
        veteranName: { $set: action.payload.veteran.name },
        errorCode: { $set: null}
      },
      inProgressTasks: { $set: updatedInProgressTasks },
      completedTasks: { $set:  updatedCompletedTasks }
    });
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_FAIL:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.FAIL
        },
        errorCode: { $set: action.payload.responseErrorCode}
      }
    });
  case ACTIONS.TASK_DEFAULT_PAGE:
    return update(state, {currentTab: {$set: action.payload.currentTab}})
  }
  return state;
};
