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

export const setIsPreDocket = (isPreDocket) => ({
  type: ACTIONS.SET_IS_PREDOCKET,
  payload: {
    isPreDocket
  },
  meta: {
    analytics: {
      label: isPreDocket
    }
  }
});
