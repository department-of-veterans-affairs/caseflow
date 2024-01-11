import ACD_LEVERS from '../../constants/ACD_LEVERS';

export const findOption = (lever, value) => lever.options.find((option) => option.item === value);

export const createCombinationValue = (toggleValue, value) => `${toggleValue}-${value}`;


/**
 * Add backendValue attributes to each lever
 * For radio and combination levers add currentValue
 */
export const createUpdatedLeversWithValues = (levers) => {
  const leverGroups = Object.keys(levers);

  const leversWithValues = () => {
    return leverGroups.reduce((updatedLevers, leverGroup) => {
      updatedLevers[leverGroup] = levers[leverGroup].map((lever) => {
        let additionalValues = {
          backendValue: lever.value
        };

        const dataType = lever.data_type;

        // Only add a new property for radio and combination data types as these have special handling logic
        // to retrieve value
        if (dataType === ACD_LEVERS.data_types.radio) {
          additionalValues = {
            currentValue: findOption(lever, lever.value).value,
            backendValue: findOption(lever, lever.value).value,
          };
        } else if (dataType === ACD_LEVERS.data_types.combination) {
          additionalValues = {
            currentValue: createCombinationValue(lever.is_toggle_active, lever.value),
            backendValue: createCombinationValue(lever.is_toggle_active, lever.value)
          };
        }

        return {
          ...lever,
          ...additionalValues
        };
      });

      return updatedLevers;
    }, {});
  };

  return leversWithValues();
};

export const formatLeverHistory = (leverHistoryList) => {
  let formattedLeverHistory = [];

  leverHistoryList.forEach((leverHistoryEntry) => {

    formattedLeverHistory.push(
      {
        user_name: leverHistoryEntry.user,
        created_at: leverHistoryEntry.created_at,
        lever_title: leverHistoryEntry.title,
        original_value: leverHistoryEntry.original_value,
        current_value: leverHistoryEntry.current_value
      }
    );
  });

  return formattedLeverHistory;
};
