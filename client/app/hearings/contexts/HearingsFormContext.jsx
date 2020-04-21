import React from 'react';
import { update } from '../../util/ReducerUtil';
import PropTypes from 'prop-types';

const HearingsFormContext = React.createContext();

const initialState = {
  hearingForms: {},
  updated: false
};

export const SET_UPDATED = 'setUpdated';
export const SET_ALL_HEARING_FORMS = 'setAllHearingForms';
export const UPDATE_HEARING_DETAILS = 'hearingDetailsForm';
export const UPDATE_TRANSCRIPTION = 'transcriptionDetailsForm';
export const UPDATE_VIRTUAL_HEARING = 'virtualHearingForm';
export const UPDATE_ASSIGN_HEARING = 'assignHearingForm';
export const UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION = 'scheduleHearingLaterWithAdminActionForm';

const UPDATE_FORMS = [
  UPDATE_HEARING_DETAILS, UPDATE_TRANSCRIPTION,
  UPDATE_VIRTUAL_HEARING, UPDATE_ASSIGN_HEARING,
  UPDATE_SCHEDULE_HEARING_LATER_WITH_ADMIN_ACTION
];

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
  let modifidedState = updateForm(UPDATE_HEARING_DETAILS, state, hearingDetailsForm);

  modifidedState = updateForm(UPDATE_VIRTUAL_HEARING, modifidedState, virtualHearingForm);
  modifidedState = updateForm(UPDATE_TRANSCRIPTION, modifidedState, transcriptionDetailsForm);

  return setUpdated(modifidedState, false);
};

const reducer = (state, action) => {
  if (action.type === SET_UPDATED) {
    return setUpdated(state, action.payload);
  } else if (action.type === SET_ALL_HEARING_FORMS) {
    return setAllHearingForms(state, action.payload);
  } else if (UPDATE_FORMS.includes(action.type)) {
    return updateForm(action.type, state, action.payload);
  }

  return state;
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
