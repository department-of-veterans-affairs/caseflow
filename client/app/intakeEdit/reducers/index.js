import { ACTIONS } from '../constants';
import { REQUEST_STATE } from '../../intakeCommon/constants';
import { update } from '../../util/ReducerUtil';
import { formatRatings, getSelection } from '../../intakeCommon/util';
import _ from 'lodash';

export const mapDataToInitialState = function(props = {}) {
  const ratings = formatRatings(props.ratings, props.ratedRequestIssues);

  return {
    formType: props.formType,
    review: props.review,
    ratings,
    originalSelection: getSelection(ratings),
    ratingsChanged: false,
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
    return state;
  }
};
