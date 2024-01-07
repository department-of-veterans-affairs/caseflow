import { createSelector } from 'reselect';
const getCaseDistributionLeverState = (state) => {
  return state.caseDistributionLevers.levers || [];
};
const getLeversByGroupConstant = (state, group) => {
  const caseDistributionLevers = getCaseDistributionLeverState(state)
  return caseDistributionLevers[group]
};
export const getLeversByGroup = createSelector(
  [getLeversByGroupConstant],
  (leversByGroup) => {
    console.log({leversByGroup})
    return leversByGroup
  }
);
