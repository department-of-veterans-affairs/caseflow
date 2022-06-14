import React, { createContext, useState, useReducer } from 'react';
import PropTypes from 'prop-types';

const HearingTypeConversionContext = createContext({});

export const HearingTypeConversionProvider = ({ children, initialAppeal }) => {
  // Create state for appellant timezone check
  const [isAppellantTZEmpty, setIsAppellantTZEmpty] = useState(!initialAppeal?.appellantTz);

  /* eslint-disable camelcase */
  const [isRepTZEmpty, setIsRepTZEmpty] = useState(!initialAppeal?.powerOfAttorney?.representative_tz);

  const [originalEmail, setOriginalEmail] = useState(initialAppeal?.veteranInfo?.veteran?.email_address || '');
  /* eslint-enable camelcase */

  // Create state to check if confirm field is empty
  const [confirmIsEmpty, setConfirmIsEmpty] = useState(true);

  const [emailsMismatch, setEmailsMismatch] = useState(true);

  // initiliaze hook to manage state for email validation
  const [isNotValidEmail, setIsNotValidEmail] = useState(true);

  const updateAppellantEmail = (appeal, email) => {
    appeal.appellantEmailAddress = email;

    return appeal;
  };

  const updateAppellantConfirmEmail = (appeal, email) => {
    appeal.appellantConfirmEmailAddress = email;

    return appeal;
  };

  const updateAppellantTimezone = (appeal, timezone) => {
    appeal.appellantTz = timezone;

    return appeal;
  };

  const updatePoaTimezone = (appeal, timezone) => {
    appeal.representativeTz = timezone;

    return appeal;
  };

  const reducer = (appeal, action) => {
    switch (action.type) {
    case 'SET_APPELLANT_EMAIL':
      return updateAppellantEmail(appeal, action.payload);
    case 'SET_APPELLANT_CONFIRM_EMAIL':
      return updateAppellantConfirmEmail(appeal, action.payload);
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
    isNotValidEmail,
    originalEmail,
    emailsMismatch,
    setIsAppellantTZEmpty,
    setIsRepTZEmpty,
    setConfirmIsEmpty,
    setIsNotValidEmail,
    setOriginalEmail,
    setEmailsMismatch,
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
