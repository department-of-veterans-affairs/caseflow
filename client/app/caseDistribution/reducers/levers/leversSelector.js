import { createSelector } from 'reselect';
import { Constant } from '../../constants';
const getLevers = (state, leverSet) => {
  return state.caseDistributionLevers[leverSet] || [];
};
const getLeversByGroupConstant = (state, leverSet, groupName) => {
  return getLevers(state, leverSet)[groupName] || []
};


export const getLeversByGroup = createSelector(
  [getLeversByGroupConstant],
  (leversByGroup) => {
    return leversByGroup
  }
);
