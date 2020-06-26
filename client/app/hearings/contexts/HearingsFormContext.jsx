import React from 'react';
import { update } from '../../util/ReducerUtil';
import PropTypes from 'prop-types';
import * as DateUtil from '../../util/DateUtil';
import { values } from 'lodash';

const HearingsFormContext = React.createContext();

export const SET_UPDATED = 'setUpdated';
export const SET_ALL_HEARING_FORMS = 'setAllHearingForms';
export const UPDATE_HEARING_DETAILS = 'hearingDetailsForm';
export const UPDATE_TRANSCRIPTION = 'transcriptionDetailsForm';
export const UPDATE_VIRTUAL_HEARING = 'virtualHearing';

const UPDATE_FORMS = [UPDATE_HEARING_DETAILS, UPDATE_TRANSCRIPTION, UPDATE_VIRTUAL_HEARING];

const setUpdated = (state, value) => ({ ...state, updated: value });

const updateForm = (form, state, values) => {
  const formState = state.hearing[form] || {};

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

const setAllHearingForms = (state, { hearingDetailsForm, transcriptionDetailsForm, virtualHearing }) => {
  let modifidedState = updateForm(UPDATE_HEARING_DETAILS, state, hearingDetailsForm);

  modifidedState = updateForm(UPDATE_VIRTUAL_HEARING, modifidedState, virtualHearing);
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

const initialState = (hearing) => {
  return {
    ...hearing,
    judgeId: hearing.judgeId ? hearing.judgeId.toString() : null,
    evidenceWindowWaived: hearing.evidenceWindowWaived || false,
    emailEvents: values(hearing?.emailEvents),
    // Transcription Request
    transcriptSentDate: DateUtil.formatDateStr(hearing.transcriptSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
    transcription: {
      ...hearing.transcription || {},
      sentToTranscriberDate: DateUtil.formatDateStr(hearing.transcription?.sentToTranscriberDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      expectedReturnDate: DateUtil.formatDateStr(hearing.transcription?.expectedReturnDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      uploadedToVbmsDate: DateUtil.formatDateStr(hearing.transcription?.uploadedToVbmsDate, 'YYYY-MM-DD', 'YYYY-MM-DD'),
      // Transcription Problem
      problemNoticeSentDate: DateUtil.formatDateStr(hearing.transcription?.problemNoticeSentDate, 'YYYY-MM-DD', 'YYYY-MM-DD')

    },
    updated: false
  };
};

const HearingsFormContextProvider = ({ children, hearing }) => {
  const [state, dispatch] = React.useReducer(reducer, initialState(hearing));

  console.log('HEARING', state);

  return (
    <HearingsFormContext.Provider value={{ state, dispatch }}>
      {children}
    </HearingsFormContext.Provider>
  );
};

HearingsFormContextProvider.propTypes = {
  children: PropTypes.node,
  hearing: PropTypes.object
};

export { HearingsFormContext, HearingsFormContextProvider };
