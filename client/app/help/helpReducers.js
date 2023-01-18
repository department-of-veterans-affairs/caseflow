import { update } from '../util/ReducerUtil';
import { ACTIONS } from './helpConstants';

export const initialState = {
  messages: {
    success: null,
    error: null
  },
  featureToggles: {},
  userRole: '',
  userCssId: '',
  userInfo: null,
  organizations: [],
  activeOrganization: {
    id: null,
    name: null,
    isVso: false
  },
  userIsVsoEmployee: false,
  userIsCamoEmployee: false,
  feedbackUrl: '#',
  loadedUserId: null,
};

const helpReducer = (state = initialState, action = {}) => {
  switch (action) {
  case ACTIONS.SET_ORGANIZATIONS:
    return update(state, {
      organizations: {
        $set: action.payload.organizations
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

export default helpReducer;
