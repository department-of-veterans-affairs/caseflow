import { ACTIONS } from '../../intake/constants';
import { update } from '../../util/ReducerUtil';
import { formatRatings } from '../../intakeCommon/util';

export const mapDataToInitialState = function(props = {}) {
  return {
    formType: props.formType,
    review: props.review,
    ratings: formatRatings(props.ratings, props.ratedRequestIssues)
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
  default:
    return state;
  }
};
