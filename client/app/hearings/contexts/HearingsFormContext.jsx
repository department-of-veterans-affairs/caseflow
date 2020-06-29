import React from 'react';
import PropTypes from 'prop-types';
import * as DateUtil from '../../util/DateUtil';
import { values, isEmpty } from 'lodash';
import { deepDiff } from '../utils';

const HearingsFormContext = React.createContext();

export const RESET_HEARING = 'reset';
export const SET_UPDATED = 'setUpdated';

const formatHearing = (hearing) => ({
  ...hearing,
  judgeId: hearing.judgeId ? hearing.judgeId.toString() : null,
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

const setUpdated = (state, value) => ({
  ...state,
  hearing: { ...state.hearing, ...value },
  formsUpdated: !isEmpty(deepDiff(state.initialHearing, { ...state.hearing, ...value }))
});

const reset = (state, hearing) => ({
  ...state,
  initialHearing: hearing,
  hearing: formatHearing(hearing),
  formsUpdated: false
});

const reducer = (state, action) => {
  switch (action.type) {
  case SET_UPDATED:
    return setUpdated(state, action.payload);
  case RESET_HEARING:
    return reset(state, action.payload);
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
