import { ACTIONS } from '../constants';

export const setInformalConference = (informalConference) => ({
  type: ACTIONS.SET_INFORMAL_CONFERENCE,
  payload: {
    informalConference
  },
  meta: {
    analytics: {
      label: informalConference
    }
  }
});

export const setSameOffice = (sameOffice) => ({
  type: ACTIONS.SET_SAME_OFFICE,
  payload: {
    sameOffice
  },
  meta: {
    analytics: {
      label: sameOffice
    }
  }
});
