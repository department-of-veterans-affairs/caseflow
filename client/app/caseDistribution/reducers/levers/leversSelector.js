import { createSelector } from 'reselect';
import { Constant } from '../../constants';
const getLevers = (state, leverSet) => {
  return state.caseDistributionLevers[leverSet] || [];
};
const getLeversByGroupConstant = (state, leverSet, groupName) => {
  return getLevers(state, leverSet)[groupName] || []
};

const getAdminStatus = (state) => {
  return state.caseDistributionLevers.isUserAcdAdmin
};

const countChangedLevers = state => {
  const flattenLevers = Object.values(state.levers).flat();
  const flattenBackendLevers = Object.values(state.backendLevers).flat();
  const changedLevers = flattenLevers.filter((lever, index) => {
    const backendValue = flattenBackendLevers[index].backendValue;
    const currentValue = lever.currentValue;
    // Check if backendValue and currentValue are different
    return backendValue !== currentValue;
  });
  return changedLevers.length;
};

export const getLeversByGroup = createSelector(
  [getLeversByGroupConstant],
  (leversByGroup) => {
    return leversByGroup
  }
);

export const getUserIsAcdAdmin = createSelector(
  [getAdminStatus],
  (userIsAcdAdmin) => {
    return userIsAcdAdmin
  }
);

export const haveLeversChanged = createSelector(
  [countChangedLevers],
  count => count > 0
);
