import StringUtil from './StringUtil';
import moment from 'moment';
// https://stackoverflow.com/questions/5306680/move-an-array-element-from-one-array-position-to-another/5306832#5306832
import 'array.prototype.move';
import _ from 'lodash';

const ZERO_INDEX_MONTH_OFFSET = 1;

export const dateFormatString = 'MM/DD/YYYY';

export const formatDate = function(dateString) {
  let date = new Date(dateString);
  let month = StringUtil.leftPad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  let day = StringUtil.leftPad(date.getDate(), 2, '0');
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};

export const formatDateStr = (dateString, dateFormat = 'YYYY-MM-DD', expectedFormat = dateFormatString) => (
  moment(dateString, dateFormat).format(expectedFormat)
);

const YEAR_INDEX = 0;
const MONTH_INDEX = 1;
const DAY_INDEX = 2;
const DASH = '-';
const SLASH = '/';

export const doDatesMatch = (date, query) => {

  // date format passed in needs be in YYYY-MM-DD
  // example: 2016-06-12
  const docDateTokens = date.split(DASH);

  // move year to the end of the array to match
  // MM-DD-YYYY format
  const updatedDocDateTokens = [docDateTokens[MONTH_INDEX], docDateTokens[DAY_INDEX], docDateTokens[YEAR_INDEX]];
  let searchQueryTokens = query.toLowerCase().split(DASH);

  // if no dashes exist in the query
  if (!_.includes(query, DASH)) {
    searchQueryTokens = query.toLowerCase().split(SLASH);
  }

  let hasMatched = true;

  searchQueryTokens.forEach((queryToken, index) => {
    if (!_.includes(updatedDocDateTokens[index], queryToken)) {
      hasMatched = false;
    }
  });

  return hasMatched;
};
