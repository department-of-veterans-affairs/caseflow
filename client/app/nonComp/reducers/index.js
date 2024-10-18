import { ACTIONS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { update } from '../../util/ReducerUtil';
import { combineReducers } from 'redux';
import orgUserReducer from '../actions/usersSlice';
import changeHistoryReducer from '../actions/changeHistorySlice';
import savedSearchReducer from '../actions/savedSearchSlice';
import { timeFunction } from '../../util/PerfDebug';

export const mapDataToInitialState = function(props = {}) {
  const { serverNonComp } = props;

  const state = {};

  state.nonComp = serverNonComp;
  state.nonComp.selectedTask = null;
  state.nonComp.decisionIssuesStatus = {};

  return state;
};

export const nonCompReducer = (state = mapDataToInitialState, action) => {
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
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.SUCCEED
        },
        claimantName: { $set: action.payload.claimant },
        errorCode: { $set: null },
      },
      taskFilterDetails: {
        $set: action.payload.taskFilterDetails
      }
    });
  case ACTIONS.TASK_UPDATE_DECISION_ISSUES_FAIL:
    return update(state, {
      decisionIssuesStatus: {
        update: {
          $set: DECISION_ISSUE_UPDATE_STATUS.FAIL
        },
        errorCode: {
          $set: action.payload.responseErrorCode
        }
      }
    });
  case ACTIONS.TASK_DEFAULT_PAGE:
    return update(state, {
      currentTab: {
        $set: action.payload.currentTab
      }
    });
  case ACTIONS.STARTED_LOADING_POWER_OF_ATTORNEY_VALUE:
    return update(state, {
      loadingPowerOfAttorney: {
        $set: { loading: true }
      }
    });
  case ACTIONS.RECEIVED_POWER_OF_ATTORNEY:
    return update(state, {
      loadingPowerOfAttorney: {
        loading: {
          $set: false
        },
        error: { $set: action.payload.error },
      },
      task: {
        power_of_attorney: {
          $set: action.payload.response
        }
      }
    });
  case ACTIONS.ERROR_ON_RECEIVE_POWER_OF_ATTORNEY_VALUE:
    return update(state, {
      loadingPowerOfAttorney: {
        $set: { error: action.payload.error }
      }
    });
  case ACTIONS.SET_POA_REFRESH_ALERT:
    return update(state, {
      poaAlert: {
        alertType: { $set: action.payload.alertType },
        message: { $set: action.payload.message },
        powerOfAttorney: { $set: action.payload.powerOfAttorney }
      }
    });
  default:
    return state;
  }
};

const combinedReducer = combineReducers({
  nonComp: nonCompReducer,
  orgUsers: orgUserReducer,
  changeHistory: changeHistoryReducer,
  savedSearch: savedSearchReducer
});

export default timeFunction(
  combinedReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);

