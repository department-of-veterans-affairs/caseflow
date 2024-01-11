import { createSelector } from 'reselect';
import ACD_LEVERS from '../../../../constants/ACD_LEVERS';

const getStore = (state) => {
  return state.caseDistributionLevers;
};

const getLevers = (state) => {
  return getStore(state).levers;
};
const getAttribute = (state, attribute) => {
  return getStore(state)[attribute];
};

const getLeversByGroupConstant = (state, attribute, groupName) => {
  return getAttribute(state, attribute)[groupName] || [];
};

/**
 * WILL NEED UPDATING WHEN RADIO AND COMBINATION LEVERS ARE EDITABLE
 */
export const changedLevers = createSelector(
  [getLevers],
  (levers) => {
    return Object.values(levers).flat().
      filter((lever) =>
        lever.data_type !== ACD_LEVERS.data_types.radio &&
        lever.data_type !== ACD_LEVERS.data_types.combination &&
        lever.backendValue !== null &&
        `${lever.value}` !== lever.backendValue
      );
  }
);

export const getLeversByGroup = createSelector(
  [getLeversByGroupConstant],
  (leversByGroup) => {
    return leversByGroup;
  }
);
