
const leverInputValidation = (lever, event, currentMessageState) => {
  const checkIsInRange = () => {
    let validNumber = (/^\d{1,5}$/).test(event);
    let withinLimits = ((lever.min_value) <= event && event <= (lever.max_value));

    if (validNumber && withinLimits) {
      return true;
    }

    return false;
  };

  let updatedMessages = {};
  let response = {};

  // Checks if value is a valid digit and within the min / max value for the lever.
  if (checkIsInRange()) {
    updatedMessages = { ...currentMessageState, [lever.item]: null };
  } else {
    updatedMessages = { ...currentMessageState,
      [lever.item]: `Please enter a value from ${ lever.min_value } to ${ lever.max_value }`
    };
  }

  let messageValues = Object.values(updatedMessages);
  let hasErrorMessage = (message) => message !== null;
  let messageFilter = messageValues.filter(hasErrorMessage);

  if (messageFilter < 1) {
    response = {
      updatedMessages,
      statement: 'SUCCESS',
      value: event,
    };

    return response;
  }

  response = {
    updatedMessages,
    statement: 'FAIL',
    value: event,
  };

  return response;
};

leverInputValidation.propTypes = {};

export default leverInputValidation;
