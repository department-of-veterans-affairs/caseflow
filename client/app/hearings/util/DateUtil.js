import moment from 'moment';
import 'moment-timezone';

export const getDateTime = (date) => {
  return moment(date).tz('America/New_York').
    format('h:mm a z');
};

export const getDate = (date) => {
  return moment(date).tz('America/New_York').
    format('l');
};
