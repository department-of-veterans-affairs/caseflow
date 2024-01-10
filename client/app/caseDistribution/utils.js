import leverStore from './reducers/levers/leversReducer';
import { Constant } from './constants';

export const checkIfOtherChangesExist = (currentLever) => {
  // this isn't going to work as is because levers is currently split up into grouping
  /*
    The code will look something like:
    const countChangedItems = (state = initialState) => {
  const { levers } = state;
  // Flatten the array of lever groups into a single array
  const allLevers = Object.values(levers).flat();
  // Use reduce to count the number of items where hasItemChanged is true
  const changedItemsCount = allLevers.reduce((count, lever) => {
    return lever.hasItemChanged ? count + 1 : count;
  }, 0);
  return changedItemsCount;
};

    })
  */
  const leversWithChangesList = leverStore.getState().levers.filter(
    (lever) => lever.hasValueChanged === true && lever.item !== currentLever.item
  );

  return leversWithChangesList.length > 0;
};

const findOptionValue = (lever, value) => lever.options.find((option) => option.item === value).value;

const createDocketDistributionPriorValue = (toggleValue, value) => `${toggleValue}-${value}`;

export const createUpdatedLever = (state, action) => {
  const { leverGroup, leverItem, value, optionValue, toggleValue } = action.payload;
  const updateLeverValue = (lever) => {
    if (leverGroup === Constant.AFFINITY) {
      const selectedOption = findOptionValue(lever, value);

      selectedOption.value = optionValue;

      return { ...lever, value: optionValue };
    } else if (leverGroup === Constant.DOCKET_DISTRIBUTION_PRIOR) {
      const newValue = createDocketDistributionPriorValue(toggleValue, value);

      return { ...lever, value: newValue, is_toggle_active: toggleValue };
    }

    return { ...lever, value };
  };

  return state.levers[leverGroup].map((lever) =>
    lever.item === leverItem ? updateLeverValue(lever) : lever
  );
};

/**
 * Add backendValue and currentValue attributes to each lever
 */
export const createUpdatedLeversWithValues = (levers) => {
  const leverGroups = Object.keys(levers);

  const leversWithValues = () => {
    return leverGroups.reduce((updatedLevers, leverGroup) => {
      updatedLevers[leverGroup] = levers[leverGroup].map((lever) => {
        let value = null;
        const group = lever.lever_group;

        if (group === Constant.AFFINITY) {
          value = findOptionValue(lever, lever.value).value;
        } else if (group === Constant.DOCKET_DISTRIBUTION_PRIOR) {
          value = createDocketDistributionPriorValue(lever.is_toggle_active, lever.value);
        } else {
          value = lever.value;
        }

        return {
          ...lever,
          backendValue: value,
        };
      });

      return updatedLevers;
    }, {});
  };

  return leversWithValues();
};

export const formatLeverHistory = (lever_history_list) => {
  let formatted_lever_history = [];

  lever_history_list.forEach((lever_history_entry) => {

    formatted_lever_history.push(
      {
        user_name: lever_history_entry.user,
        created_at: lever_history_entry.created_at,
        lever_title: lever_history_entry.title,
        original_value: lever_history_entry.original_value,
        current_value: lever_history_entry.current_value
      }
    );
  });

  return formatted_lever_history;
};
