import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES.json';
import moment from 'moment';
import _ from 'lodash';

export const isPreviouslyScheduledHearing = (hearing) => (
  hearing.disposition === HEARING_DISPOSITION_TYPES.postponed ||
    hearing.disposition === HEARING_DISPOSITION_TYPES.cancelled
);

export const now = () => {
  return moment().tz(moment.tz.guess()).
    format('h:mm a');
};

export const sortHearings = (hearings) => (
  _.orderBy(Object.values(hearings || {}), (hearing) => hearing.scheduledFor, 'asc')
);
