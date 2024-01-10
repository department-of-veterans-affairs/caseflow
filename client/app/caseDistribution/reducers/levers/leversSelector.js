import { createSelector } from 'reselect';
const getLevers = (state, leverSet) => {
  return state.caseDistributionLevers[leverSet] || [];
};
const getLeversByGroupConstant = (state, leverSet, groupName) => {
  return getLevers(state, leverSet)[groupName] || [];
};

const countChangedLevers = (state) => {
  const flattenLevers = Object.values(state.levers).flat();
  const flattenBackendLevers = Object.values(state.backendLevers).flat();
  const changedLevers = flattenLevers.filter((lever, index) => {
    const backendValue = flattenBackendLevers[index].backendValue;
    const value = lever.value;

    // Check if backendValue and currentValue are different
    return backendValue !== value;
  });

  return changedLevers.length;
};

export const getLeversByGroup = createSelector(
  [getLeversByGroupConstant],
  (leversByGroup) => {
    return leversByGroup;
  }
);

export const haveLeversChanged = createSelector(
  [countChangedLevers],
  (count) => count > 0
);
