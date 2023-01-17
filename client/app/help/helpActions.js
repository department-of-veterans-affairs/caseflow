import { ACTIONS } from './helpConstants';

export const setOrganizations = (organizations) => ({
  type: ACTIONS.SET_ORGANIZATIONS,
  payload: { organizations }
});

export const setOrganizationMembershipRequests = (organizationMembershipRequests) => ({
  type: ACTIONS.SET_ORGANIZATION_MEMBERSHIP_REQUESTS,
  payload: { organizationMembershipRequests }
});
