import React from 'react';
import PropTypes from 'prop-types';
import * as DateUtil from '../../util/DateUtil';
import { values, isEmpty } from 'lodash';
import { deepDiff } from '../utils';

const HearingsFormContext = React.createContext();

const formatHearing = (hearing) => ({
  ...hearing,
  judgeId: hearing.judgeId?.toString(),
  evidenceWindowWaived: hearing.evidenceWindowWaived || false,
  emailEvents: values(hearing?.emailEvents),
  // Transcription Request
  transcriptSentDate: DateUtil.formatDateStr(
    hearing.transcriptSentDate,
    'YYYY-MM-DD',
    'YYYY-MM-DD'
  ),
  transcription: {
    ...(hearing.transcription || {}),
    sentToTranscriberDate: DateUtil.formatDateStr(
      hearing.transcription?.sentToTranscriberDate,
      'YYYY-MM-DD',
      'YYYY-MM-DD'
    ),
    expectedReturnDate: DateUtil.formatDateStr(
      hearing.transcription?.expectedReturnDate,
      'YYYY-MM-DD',
      'YYYY-MM-DD'
    ),
    uploadedToVbmsDate: DateUtil.formatDateStr(
      hearing.transcription?.uploadedToVbmsDate,
      'YYYY-MM-DD',
      'YYYY-MM-DD'
    ),
    // Transcription Problem
    problemNoticeSentDate: DateUtil.formatDateStr(
      hearing.transcription?.problemNoticeSentDate,
      'YYYY-MM-DD',
      'YYYY-MM-DD'
    )
  }
});

export const SET_UPDATED = 'setUpdated';
const setUpdated = (state, value) => {
  const newHearing = { ...state.hearing, ...value };

  return {
    ...state,
    hearing: newHearing,
    formsUpdated: !isEmpty(deepDiff(state.initialHearing, newHearing))
  };
};

// Full reset of everything.
export const RESET_HEARING = 'reset';
const reset = (state, hearing) => ({
  ...state,
  initialHearing: formatHearing(hearing),
  hearing: formatHearing(hearing),
  formsUpdated: false
});

export const RESET_VIRTUAL_HEARING = 'resetVirtualHearing';

// Resets only the `virtualHearing` and `emailEvents` field, and should preserve all other fields.
// NOTE: Only used for resetting states during polling
const resetVirtualHearing = (state, payload) => {
  const newHearing = {
    ...state.hearing,
    emailEvents: values(payload.emailEvents),
    virtualHearing: {
      ...(state.hearing?.virtualHearing || {}),
      ...payload.virtualHearing
    }
  };
  const newInitialHearing = {
    ...state.initialHearing,
    virtualHearing: {
      ...(state.initialHearing?.virtualHearing || {}),
      ...payload.virtualHearing
    }
  };

  return {
    ...state,
    initialHearing: newInitialHearing,
    hearing: newHearing,
    formsUpdated: !isEmpty(deepDiff(newInitialHearing, newHearing))
  };
};

const reducer = (state, action) => {
  switch (action.type) {
  case SET_UPDATED:
    return setUpdated(state, action.payload);
  case RESET_HEARING:
    return reset(state, action.payload);
  case RESET_VIRTUAL_HEARING:
    return resetVirtualHearing(state, action.payload);
  default:
    return state;
  }
};

const initialState = (hearing) => {
  return {
    formsUpdated: false,
    initialHearing: formatHearing(hearing),
    hearing: formatHearing(hearing)
  };
};

export const updateHearingDispatcher = (hearing, dispatch) => (type, changes) => {
  const payload =
    type === 'hearing' ?
      {
        ...hearing,
        ...changes,
      } :
      {
        ...hearing,
        [type]: {
          ...hearing[type],
          ...changes,
        },
      };

  return dispatch({ type: SET_UPDATED, payload });
};

const HearingsFormContextProvider = ({ children, hearing }) => {
  const [state, dispatch] = React.useReducer(reducer, initialState(hearing));

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
