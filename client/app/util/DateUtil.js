import moment from 'moment';

const MILLISECONDS_IN_A_DAY = 86400000;

export const formatDate = function(dateString) {
  return moment(dateString, 'MM-DD-YYYY').format('MM/DD/YYYY');
};

export const addDays = function(date, days) {
  let milliseconds = days * MILLISECONDS_IN_A_DAY;
  let dateString = date.getTime() + milliseconds;

  return new Date(dateString);
};
