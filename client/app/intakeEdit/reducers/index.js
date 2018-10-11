import { ACTIONS } from '../../intake/constants';
import { applyCommonReducers } from '../../intake/reducers/common';
import { REQUEST_STATE } from '../../intakeCommon/constants';
import { update } from '../../util/ReducerUtil';
import { formatRatings, getSelection } from '../../intakeCommon/util';
import { formatRequestIssues } from '../../intake/util/issues';
import _ from 'lodash';

export const mapDataToInitialState = function(props = {}) {
  const { serverIntake } = props;

  serverIntake.ratings = formatRatings(serverIntake.ratings)

  return {
    ...serverIntake,
    addIssuesModalVisible: false,
    nonRatedIssueModalVisible: false,
    addedIssues: formatRequestIssues(serverIntake.requestIssues),

    // ratings: formatRatings(props.review.ratings, props.review.rated_request_issues),
    // originalSelection: getSelection(ratings),
    // ratingsChanged: false,
    requestStatus: {
      requestIssuesUpdate: REQUEST_STATE.NOT_STARTED
    },
    responseErrorCode: null
  };
};

export const intakeEditReducer = (state = mapDataToInitialState(), action) => {
  let newRatings;
  let serverRatings;
  let ratingsChanged;

  console.log(state)

  switch (action.type) {
  case ACTIONS.SET_ISSUE_SELECTED:
    newRatings = update(state.ratings, {
      [action.payload.profileDate]: {
        issues: {
          [action.payload.issueId]: {
            isSelected: {
              $set: action.payload.isSelected
            }
          }
        }
      }
    });
    ratingsChanged = !_.isEqual(getSelection(newRatings), state.originalSelection);

    return update(state, {
      ratings: { $set: newRatings },
      ratingsChanged: { $set: ratingsChanged }
    });
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
