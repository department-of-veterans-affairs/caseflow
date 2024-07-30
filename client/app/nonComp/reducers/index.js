import { ACTIONS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { update } from '../../util/ReducerUtil';

export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  let state = serverNonComp;

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
          $set: DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS
        }
      }
    });
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED: {
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.SUCCEED
        },
        claimantName: { $set: action.payload.claimant },
        errorCode: { $set: null },
      },
      taskFilterDetails: { $set: action.payload.taskFilterDetails }
    });
  }
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_FAIL:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.FAIL
        },
        errorCode: { $set: action.payload.responseErrorCode }
      }
    });
  case ACTIONS.TASK_DEFAULT_PAGE:
    return update(state, { currentTab: { $set: action.payload.currentTab } });
  default:
    return state;
  }
};
