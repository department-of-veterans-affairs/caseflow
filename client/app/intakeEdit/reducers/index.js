import _ from 'lodash';
import { ACTIONS } from '../constants';
import { applyCommonReducers } from '../../intake/reducers/common';
import { REQUEST_STATE } from '../../intake/constants';
import { update } from '../../util/ReducerUtil';
import { formatRequestIssues, formatRatings, getSelection } from '../../intake/util/issues';

export const mapDataToInitialState = function(props = {}) {
  const { serverIntake } = props;
  serverIntake.ratings = formatRatings(serverIntake.ratings)

  return {
    ...serverIntake,
    addIssuesModalVisible: false,
    nonRatedIssueModalVisible: false,
    unidentifiedIssuesModalVisible: false,
    addedIssues: formatRequestIssues(serverIntake.requestIssues),
    originalIssues: formatRequestIssues(serverIntake.requestIssues),
    requestStatus: {
      requestIssuesUpdate: REQUEST_STATE.NOT_STARTED
    },
    responseErrorCode: null
  };
};

export const intakeEditReducer = (state = mapDataToInitialState(), action) => {
  let serverRatings;

  switch (action.type) {
  case ACTIONS.REQUEST_ISSUES_UPDATE_START:
    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.IN_PROGRESS
        }
      }
    });
  case ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED:
    serverRatings = formatRatings(action.payload.ratings, action.payload.ratedRequestIssues);

    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      },
      ratings: { $set: serverRatings },
      originalSelection: { $set: getSelection(serverRatings) },
      ratingsChanged: { $set: false },
      responseErrorCode: { $set: null }
    });
  case ACTIONS.REQUEST_ISSUES_UPDATE_FAIL:
    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.FAILED
        }
      },
      responseErrorCode: { $set: action.payload.responseErrorCode }
    });
  default:
    return applyCommonReducers(state, action);
  }
};
