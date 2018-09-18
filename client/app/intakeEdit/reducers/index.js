import { ACTIONS, REQUEST_STATE } from '../constants';
import { update } from '../../util/ReducerUtil';
import { formatRatings } from '../../intakeCommon/util';

export const mapDataToInitialState = function(props = {}) {
  return {
    formType: props.formType,
    review: props.review,
    ratings: formatRatings(props.ratings, props.ratedRequestIssues),
    requestStatus: {
      requestIssuesUpdate: REQUEST_STATE.NOT_STARTED
    },
    responseErrorCode: null
  };
};

export const intakeEditReducer = (state = mapDataToInitialState(), action) => {
  switch (action.type) {
  case ACTIONS.SET_ISSUE_SELECTED:
    return update(state, {
      ratings: {
        [action.payload.profileDate]: {
          issues: {
            [action.payload.issueId]: {
              isSelected: {
                $set: action.payload.isSelected
              }
            }
          }
        }
      }
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
    return update(state, {
      requestStatus: {
        requestIssuesUpdate: {
          $set: REQUEST_STATE.SUCCEEDED
        }
      },
      ratings: {
        $set: formatRatings(action.payload.ratings, action.payload.ratedRequestIssues)
      },
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
    return state;
  }
};
