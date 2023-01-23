import { update } from '../util/ReducerUtil';
import { ACTIONS } from './helpConstants';
import helpFormSlice from './helpApiSlice';
import { combineReducers } from 'redux';

export const initialState = {
  featureToggles: {},
  userRole: '',
  userCssId: '',
  userInfo: null,
  userOrganizations: [],
  feedbackUrl: '#',
  loadedUserId: null,
};

const helpReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.SET_USER_ORGANIZATIONS:
    return update(state, {
      userOrganizations: {
        $set: action.payload.userOrganizations
      }
    });
  case ACTIONS.SET_ORGANIZATION_MEMBERSHIP_REQUESTS:
    return update(state, {
      organizationMembershipRequests: {
        $set: action.payload.organizationMembershipRequests
      }
    });
  case ACTIONS.SET_FEATURE_TOGGLES:
    return update(state, {
      featureToggles: {
        $set: action.payload.featureToggles
      }
    });
  default:
    return state;
  }
};

const helpReducers = combineReducers({ help: helpReducer, form: helpFormSlice });

// export default helpReducer;
export default helpReducers;
