import React from 'react';
import { update } from '../../util/ReducerUtil';
import PropTypes from 'prop-types';

const HearingsFormContext = React.createContext();

const initialState = {
  hearingForms: {},
  updated: false
};

const setUpdated = (state, value) => ({ ...state, updated: value });

const updateForm = (form, state, values) => {
  const formState = state.hearingForms[form] || {};

  return update(state, {
    hearingForms: {
      [form]: {
        $set: values === null ?
          {} : {
            ...formState,
            ...values
          }
      }
    },
    updated: {
      $set: true
    }
  });
};

const setAllHearingForms = (state, { hearingDetailsForm, transcriptionDetailsForm, virtualHearingForm }) => {
  let modifidedState = updateForm('hearingDetailsForm', state, hearingDetailsForm);

  modifidedState = updateForm('virtualHearingForm', modifidedState, virtualHearingForm);
  modifidedState = updateForm('transcriptionDetailsForm', modifidedState, transcriptionDetailsForm);

  return setUpdated(modifidedState, false);
};

const reducer = (state, action) => {
  switch (action.type) {
  case 'setUpdated':
    return setUpdated(state, action.payload);
  case 'updateHearingDetails':
    return updateForm('hearingDetailsForm', state, action.payload);
  case 'updateVirtualHearing':
    return updateForm('virtualHearingForm', state, action.payload);
  case 'updateTranscriptionDetails':
    return updateForm('transcriptionDetailsForm', state, action.payload);
  case 'setAllHearingForms':
    return setAllHearingForms(state, action.payload);
  default:
    return state;
  }
};

const HearingsFormContextProvider = ({ children }) => {
  const [state, dispatch] = React.useReducer(reducer, initialState);

  return (
    <HearingsFormContext.Provider value={{ state, dispatch }}>
      {children}
    </HearingsFormContext.Provider>
  );
};

HearingsFormContextProvider.propTypes = {
  children: PropTypes.node
};

export { HearingsFormContext, HearingsFormContextProvider };
