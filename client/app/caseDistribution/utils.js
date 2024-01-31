import ACD_LEVERS from '../../constants/ACD_LEVERS';

export const findOption = (lever, value) => lever.options.find((option) => option.item === value);

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
            backendValue: lever.value,
            backendIsToggleActive: lever.is_toggle_active
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

export const formatTimestamp = (entry) => {
  const dateEntry = new Date(entry);
  const formattedDate = `${dateEntry.toLocaleDateString('en-US', {
    weekday: 'short',
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  }) } ${dateEntry.getHours()}:${dateEntry.getMinutes()}:${dateEntry.getSeconds()}`;

  return formattedDate;
};

export const formatLeverHistory = (leverHistoryList) => {

  if (!leverHistoryList) {
    return [];
  }

  const formattedHistory = leverHistoryList.reduce((accumulator, entry) => {
    const existingEntry = accumulator.find(
      (item) => formatTimestamp(item.created_at) === formatTimestamp(entry.created_at) &&
      item.user_css_id === entry.user_css_id
    );

    if (existingEntry) {
      existingEntry.titles.push(entry.lever_title);
      existingEntry.previous_values.push(entry.previous_value);
      existingEntry.updated_values.push(entry.update_value);
      existingEntry.units.push(entry.lever_unit || 'null');
    } else {
      const newEntry = {
        created_at: formatTimestamp(entry.created_at),
        user_css_id: entry.user_css_id,
        user_name: entry.user_name,
        titles: [entry.lever_title],
        previous_values: [entry.previous_value],
        updated_values: [entry.update_value],
        units: [entry.lever_unit || 'null'],
      };

      accumulator.push(newEntry);
    }

    return accumulator;
  }, []);

  let descendingFormattedHistory = formattedHistory.reverse();

  return descendingFormattedHistory;
};

export const validateLeverInput = (lever, value) => {
  const errors = [];
  const { min_value: minValue, max_value: maxValue } = lever;

  if (value === null || value === '') {
    errors.push({ leverItem: lever.item, message: ACD_LEVERS.validation_error_message.minimum_not_met });
  }
  if (parseFloat(value)) {
    if (value < minValue) {
      errors.push({ leverItem: lever.item, message: ACD_LEVERS.validation_error_message.minimum_not_met });
    }
    if (maxValue && value > maxValue) {
      errors.push({ leverItem: lever.item, message: ACD_LEVERS.validation_error_message.out_of_bounds });
    }
  }

  return errors;
};

export const leverErrorMessageExists = (existingErrors, newErrors) => {
  return existingErrors.some((existingError) =>
    newErrors.every((newError) =>
      JSON.stringify(existingError) === JSON.stringify(newError)
    )
  );
};

/**
 * if is_toggle_active was false then set to true and value was updated
 *   return true
 * if is_toggle_active was true, value was updated then is_toggle_active was set to false
 *   return true
 * if is_toggle_active didn't change, value was udpated
 *   return true
 * if neither value or is_toggle_active changed
 *   return false
 */
export const hasCombinationLeverChanged = (lever) =>
  (lever.backendIsToggleActive !== lever.is_toggle_active) ||
  (lever.backendValue !== null &&
  `${lever.value}` !== lever.backendValue);

export const hasRadioLeverChanged = (lever) => false;
