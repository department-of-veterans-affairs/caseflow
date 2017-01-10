import { leftPad } from './StringUtil';

const ZERO_INDEX_MONTH_OFFSET = 1;

export const formatDate = function(dateString) {
  let date = new Date(dateString);
  let month = leftPad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  let day = leftPad(date.getDate(), 2, '0');
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};
