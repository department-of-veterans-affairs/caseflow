import StringUtil from './StringUtil';
import moment from 'moment';
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

export const doDatesMatch = (date, query) => {
  const DAY_INDEX = 2;
  const DASH = '-';
  const SLASH = '/';

  // date format passed in needs be in YYYY-MM-DD
  // example: 2016-06-12
  let docDateTokens = date.split(DASH);

  // move year to the end of the array to match
  // MM-DD-YYYY format
  docDateTokens.move(0, DAY_INDEX);

  let searchQueryTokens = query.toLowerCase().split(DASH);

  // if no dashes exist in the query
  if (!_.includes(query, DASH)) {
    searchQueryTokens = query.toLowerCase().split(SLASH);
  }

  let hasMatched = true;

  searchQueryTokens.forEach((queryToken, index) => {
    if (!_.includes(docDateTokens[index], queryToken)) {
      hasMatched = false;
    }
  });

  return hasMatched;
};
