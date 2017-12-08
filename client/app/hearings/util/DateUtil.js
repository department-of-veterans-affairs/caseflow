import moment from 'moment';
import 'moment-timezone';

export const getDate = (date) => {
  return moment(date).tz('America/New_York').
    format('h:mm a z');
};
