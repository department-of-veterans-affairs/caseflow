import { ACTIONS } from './helpConstants';

export const setUserOrganizations = (userOrganizations) => ({
  type: ACTIONS.SET_USER_ORGANIZATIONS,
  payload: { userOrganizations }
});

export const setOrganizationMembershipRequests = (organizationMembershipRequests) => ({
  type: ACTIONS.SET_ORGANIZATION_MEMBERSHIP_REQUESTS,
  payload: { organizationMembershipRequests }
});

export const setFeatureToggles = (featureToggles) => ({
  type: ACTIONS.SET_FEATURE_TOGGLES,
  payload: { featureToggles }
});
