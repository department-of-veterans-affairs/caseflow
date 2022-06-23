import React, { createContext, useState, useReducer } from 'react';
import PropTypes from 'prop-types';

const HearingTypeConversionContext = createContext({});

export const SET_UPDATED = 'setUpdated';
const setUpdated = (appeal, value) => {
  return { ...appeal, ...value };
};

export const HearingTypeConversionProvider = ({ children, initialAppeal }) => {
  // initiliaze hook to manage state for email validation
  const [isNotValidEmail, setIsNotValidEmail] = useState(false);

  const reducer = (appeal, action) => {
    switch (action.type) {
    case SET_UPDATED:
      return setUpdated(appeal, action.payload);
    default:
      return appeal;
    }
  };

  const [updatedAppeal, dispatchAppeal] = useReducer(reducer, initialAppeal);

  const contextData = {
    updatedAppeal,
    isNotValidEmail,
    setIsNotValidEmail,
    dispatchAppeal
  };

  return (
    <HearingTypeConversionContext.Provider value={contextData}>
      { children }
    </HearingTypeConversionContext.Provider>
  );
};

export const updateAppealDispatcher = (appeal, dispatch) => (type, changes) => {
  const payload =
    type === 'appeal' ?
      {
        ...appeal,
        ...changes,
      } :
      {
        ...appeal,
        [type]: {
          ...appeal[type],
          ...changes,
        },
      };

  return dispatch({ type: SET_UPDATED, payload });
};

HearingTypeConversionProvider.propTypes = {
  children: PropTypes.node,
  initialAppeal: PropTypes.object
};

export default HearingTypeConversionContext;
