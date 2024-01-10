import leverStore from './reducers/levers/leversReducer';
import ACD_LEVERS from '../../constants/ACD_LEVERS';

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

export const findOption = (lever, value) => lever.options.find((option) => option.item === value);

const createCombinationValue = (toggleValue, value) => `${toggleValue}-${value}`;

/**
 * Updates levers of data type number, boolean, and text
 */
export const createUpdatedLever = (state, action) => {
  const { leverGroup, leverItem, value } = action.payload;
  let hasValueChanged = false;

  const updateLeverValue = (lever) => {
    hasValueChanged = `${value}` !== lever.backendValue;

    return { ...lever, value };
  };

  const updatedLeverGroup = state.levers[leverGroup].map((lever) =>
    lever.item === leverItem ? updateLeverValue(lever) : lever
  );

  return [updatedLeverGroup, hasValueChanged];
};

/**
 *  Do not trust this code. It is untested
 */
export const createUpdatedRadioLever = (state, action) => {
  const { leverGroup, leverItem, value, optionValue } = action.payload;
  let hasValueChanged = false;

  const updateLeverValue = (lever) => {
    const selectedOption = findOption(lever, value);

    hasValueChanged = `${optionValue}` !== lever.backendValue;

    selectedOption.value = optionValue;

    return { ...lever, currentValue: optionValue };
  };

  const updatedLeverGroup = state.levers[leverGroup].map((lever) =>
    lever.item === leverItem ? updateLeverValue(lever) : lever
  );

  return [updatedLeverGroup, hasValueChanged];
};

/**
 *  Do not trust this code. It is untested
 */
export const createUpdatedCombinationLever = (state, action) => {
  const { leverGroup, leverItem, value, toggleValue } = action.payload;
  let hasValueChanged = false;

  const updateLeverValue = (lever) => {
    const newValue = createCombinationValue(toggleValue, value);

    hasValueChanged = `${newValue}` !== lever.backendValue;

    return { ...lever, currentValue: newValue, is_toggle_active: toggleValue };
  };

  const updatedLeverGroup = state.levers[leverGroup].map((lever) =>
    lever.item === leverItem ? updateLeverValue(lever) : lever
  );

  return [updatedLeverGroup, hasValueChanged];
};

/**
 * Add backendValue attributes to each lever
 * For radio and combination levers add currentValue
 */
export const createUpdatedLeversWithValues = (levers) => {
  const leverGroups = Object.keys(levers);

  const leversWithValues = () => {
    return leverGroups.reduce((updatedLevers, leverGroup) => {
      updatedLevers[leverGroup] = levers[leverGroup].map((lever) => {
        let value = null;
        const dataType = lever.data_type;

        // Only add a new property for radio and combination data types as these have special handling logic
        // to retrieve value
        if (dataType === ACD_LEVERS.data_types.radio) {
          value = findOption(lever, lever.value).value;
        } else if (dataType === ACD_LEVERS.data_types.combination) {
          value = createCombinationValue(lever.is_toggle_active, lever.value);
        }

        return {
          ...lever,
          currentValue: value,
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
