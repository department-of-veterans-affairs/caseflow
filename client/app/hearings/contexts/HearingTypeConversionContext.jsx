import React, { createContext, useState, useReducer } from 'react';
import PropTypes from 'prop-types';

const HearingTypeConversionContext = createContext({});

export const HearingTypeConversionProvider = ({ children, initialAppeal }) => {
  // Create state for appellant timezone check
  const [isAppellantTZEmpty, setIsAppellantTZEmpty] = useState(initialAppeal.appellantTz);

  // Create state for rep timezone check
  const [isRepTZEmpty, setIsRepTZEmpty] = useState(initialAppeal.powerOfAttorney?.representative_tz);

  // Create state to check if confirm field is empty
  const [confirmIsEmpty, setConfirmIsEmpty] = useState(true);

  // initiliaze hook to manage state for email validation
  const [isNotValidEmail, setIsNotValidEmail] = useState(true);

  const [originalEmail, setOriginalEmail] = useState(initialAppeal.veteranInfo?.veteran?.email_address || '');

  const updateAppellantEmail = (appeal, email) => {
    appeal.veteranInfo.veteran.email_address = email;

    return appeal;
  };

  const updateAppellantTimezone = (appeal, timezone) => {
    appeal.appellantTz = timezone;

    return appeal;
  };

  const updatePoaTimezone = (appeal, timezone) => {
    appeal.powerOfAttorney.representative_tz = timezone;

    return appeal;
  };

  const reducer = (appeal, action) => {
    switch (action.type) {
    case 'SET_APPELLANT_EMAIL':
      return updateAppellantEmail(appeal, action.payload);
    case 'SET_APPELLANT_TZ':
      return updateAppellantTimezone(appeal, action.payload);
    case 'SET_POA_TZ':
      return updatePoaTimezone(appeal, action.payload);
    default:
      return appeal;
    }
  };

  const [updatedAppeal, dispatchAppeal] = useReducer(reducer, initialAppeal);

  const contextData = {
    updatedAppeal,
    isAppellantTZEmpty,
    isRepTZEmpty,
    confirmIsEmpty,
    confirmIsEmptyMessage,
    isNotValidEmail,
    originalEmail,
    setIsAppellantTZEmpty,
    setIsRepTZEmpty,
    setConfirmIsEmpty,
    setConfirmIsEmptyMessage,
    setIsNotValidEmail,
    setOriginalEmail,
    dispatchAppeal
  };

  return (
    <HearingTypeConversionContext.Provider value={contextData}>
      { children }
    </HearingTypeConversionContext.Provider>
  );
};

HearingTypeConversionProvider.propTypes = {
  children: PropTypes.node,
  initialAppeal: PropTypes.object
};

export default HearingTypeConversionContext;
