/* eslint-disable eqeqeq */

import PropTypes from 'prop-types';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const leverInputValidation = (lever, event, currentMessageState, initialLever, option) => {
  let maxValue = 999;

  const checkIsInRange = () => {
    let validNumber = (/^\d{1,10}$/).test(event);
    let withinLimits = ((lever.min_value) <= event);

    // Max value to override lever database maximums on majority levers

    if (lever.data_type === ACD_LEVERS.radio) {

      withinLimits = ((option.min_value) <= event && event <= maxValue);
    } else {

      withinLimits = ((lever.min_value) <= event);
    }

    if (validNumber && withinLimits) {
      return true;
    }

    return false;
  };

  let updatedMessages = {};
  let response = {};

  // Checks if value is a valid digit and within the min / max value for the lever requirements.
  if (checkIsInRange()) {
    if (lever.data_type === ACD_LEVERS.radio) {
      if (updatedMessages) {
        updatedMessages = {};
      } else {
        updatedMessages = { ...currentMessageState, [`${lever.item}-${option.item}`]: null };
      }
    } else {
      updatedMessages = { ...currentMessageState, [lever.item]: null };
    }
  } else if (lever.data_type === ACD_LEVERS.radio) {
    updatedMessages = { ...currentMessageState,
      [`${lever.item}-${option.item}`]: `Please enter a value from ${ option.min_value } to ${ maxValue }`
    };
  } else {
    updatedMessages = { ...currentMessageState,
      [lever.item]: `Please enter a value greater than or equal to ${ lever.min_value }`
    };
  }

  let messageValues = Object.values(updatedMessages);
  let hasErrorMessage = (message) => message !== null;
  let messageFilter = messageValues.filter(hasErrorMessage);

  if (lever.data_type === ACD_LEVERS.radio) {
    let initialOption = initialLever.options.find((original) => original.item === option.item);

    if (event === initialOption.value) {
      response = {
        updatedMessages,
        statement: ACD_LEVERS.DUPLICATE,
        value: event,
      };

      return response;
    }
  } else if (event == initialLever.value) {
    response = {
      updatedMessages,
      statement: ACD_LEVERS.DUPLICATE,
      value: event,
    };

    return response;
  }

  if (messageFilter < 1) {
    response = {
      updatedMessages,
      statement: ACD_LEVERS.SUCCESS,
      value: event,
    };

    return response;
  }

  response = {
    updatedMessages,
    statement: ACD_LEVERS.FAIL,
    value: event,
  };

  return response;
};

leverInputValidation.propTypes = {
  lever: PropTypes.object,
  event: PropTypes.integer,
  currentMessageState: PropTypes.object,
  initialLever: PropTypes.object,
  option: PropTypes.object,
};

export default leverInputValidation;
