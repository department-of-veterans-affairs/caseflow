import StringUtil from './StringUtil';
import * as moment from 'moment';

const ZERO_INDEX_MONTH_OFFSET = 1;

export const dateFormatString = 'MM/DD/YYYY';

export const formatDate = function(dateString) {
  let date = new Date(dateString);
  let month = StringUtil.leftPad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  let day = StringUtil.leftPad(date.getDate(), 2, '0');
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};

export const formatDateStr = (dateString, dateFormat = 'YYYY-MM-DD', expectedFormat = 'MM-DD-YYYY') => (
  moment(dateString, dateFormat).format(expectedFormat)
);
