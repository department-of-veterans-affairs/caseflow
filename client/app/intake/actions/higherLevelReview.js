import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStringForApi } from '../../util/DateUtil';
import _ from 'lodash';

const analytics = true;

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
