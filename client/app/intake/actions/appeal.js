import { ACTIONS } from '../constants';

export const setDocketType = (docketType) => ({
  type: ACTIONS.SET_DOCKET_TYPE,
  payload: {
    docketType
  },
  meta: {
    analytics: {
      label: docketType
    }
  }
});


export const setOriginalHearingRequestType = (originalHearingRequestType) => ({
  type: ACTIONS.SET_HEARING_TYPE,
  payload: {
    originalHearingRequestType
  }
});
