import React, { createContext, useState} from 'react';
import PropTypes from 'prop-types';

const HearingTypeConversionContext = createContext({});

export const HearingTypeConversionProvider = ({ children, appeal }) => {
  // Create state for appellant timezone check
  const [isAppellantTZEmpty, setIsAppellantTZEmpty] = useState(true);

  // Create state for appellant timezone error message
  const [appellantTZErrorMessage, setAppellantTZErrorMessage] = useState('');

  // Create state for rep timezone check
  const [isRepTZEmpty, setIsRepTZEmpty] = useState(true);

  // Create state for rep timezone error message
  const [repTZErrorMessage, setRepTZErrorMessage] = useState('');

  // Create state to check if confirm field is empty
  const [confirmIsEmpty, setConfirmIsEmpty] = useState(true);

  // Create state for confirmIsEmpty error message
  const [confirmIsEmptyMessage, setConfirmIsEmptyMessage] = useState('');

  // initiliaze hook to manage state for email validation
  const [isNotValidEmail, setIsNotValidEmail] = useState(true);

  const [originalEmail, setOriginalEmail] = useState('');

  const [updatedAppeal, setUpdatedAppeal] = useState(appeal);

  const updateAppeal = (key, val) => {
    setUpdatedAppeal(updateAppeal[key] = val);
  };

  const contextData = {
    isAppellantTZEmpty,
    appellantTZErrorMessage,
    isRepTZEmpty,
    repTZErrorMessage,
    confirmIsEmpty,
    confirmIsEmptyMessage,
    isNotValidEmail,
    originalEmail,
    updatedAppeal,
    setIsAppellantTZEmpty,
    setAppellantTZErrorMessage,
    setIsRepTZEmpty,
    setRepTZErrorMessage,
    setConfirmIsEmpty,
    setConfirmIsEmptyMessage,
    setIsNotValidEmail,
    setOriginalEmail,
    setUpdatedAppeal,
    updateAppeal
  };

  return (
    <HearingTypeConversionContext.Provider value={contextData}>
      { children }
    </HearingTypeConversionContext.Provider>
  );
};

HearingTypeConversionProvider.propTypes = {
  children: PropTypes.node
};

export default HearingTypeConversionContext;
