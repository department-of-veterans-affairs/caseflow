import { createSelector } from 'reselect';
import ACD_LEVERS from '../../../../constants/ACD_LEVERS';
import { findOption, createCombinationValue } from '../../utils';

const getStore = (state) => {
  return state.caseDistributionLevers;
};

export const getLevers = (state) => {
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

export const hasChangedLevers = (state) => changedLevers(state).length > 0;

export const getLeversByGroup = createSelector(
  [getLeversByGroupConstant],
  (leversByGroup) => {
    return leversByGroup;
  }
);

const updateLeverGroup = (state, leverGroup, leverItem, updateLeverValue) =>
  state.levers[leverGroup].map((lever) =>
    lever.item === leverItem ? updateLeverValue(lever) : lever
  );

/**
 * Updates levers of data type number, boolean, and text
 */
export const createUpdatedLever = (state, action) => {
  const { leverGroup, leverItem, value } = action.payload;

  const updateLeverValue = (lever) => {
    return { ...lever, value };
  };

  return updateLeverGroup(state, leverGroup, leverItem, updateLeverValue);
};

/**
 * Do not trust this code. It is untested
 * WILL NEED UPDATING WHEN RADIO AND COMBINATION LEVERS ARE EDITABLE
 */
export const createUpdatedRadioLever = (state, action) => {
  const { leverGroup, leverItem, value, optionValue } = action.payload;

  const updateLeverValue = (lever) => {
    const selectedOption = findOption(lever, value);

    selectedOption.value = optionValue;

    return { ...lever, currentValue: optionValue };
  };

  return updateLeverGroup(state, leverGroup, leverItem, updateLeverValue);
};

/**
 * Do not trust this code. It is untested
 * WILL NEED UPDATING WHEN RADIO AND COMBINATION LEVERS ARE EDITABLE
 */
export const createUpdatedCombinationLever = (state, action) => {
  const { leverGroup, leverItem, value, toggleValue } = action.payload;

  const updateLeverValue = (lever) => {
    const newValue = createCombinationValue(toggleValue, value);

    return { ...lever, currentValue: newValue, is_toggle_active: toggleValue };
  };

  return updateLeverGroup(state, leverGroup, leverItem, updateLeverValue);
};
