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

const YEAR_INDEX = 0;
const MONTH_INDEX = 1;
const DAY_INDEX = 2;
const DASH = '-';
const SLASH = '/';
const SIZE_ONE = 1;

const parseQueryToTokens = (query) => {
  // date format passed in needs be in YYYY-MM-DD
  // example: 2016-06-12
  let searchQueryTokens = query.toLowerCase().split(DASH);

  // if no dashes exist in the query
  if (!_.includes(query, DASH)) {
    searchQueryTokens = query.toLowerCase().split(SLASH);
  }

  // returning after removing empty strings from the tokens
  return searchQueryTokens;
};

const doesQueryMatchDateTokens = (docDateTokens, searchQueryTokens) => {
  let hasMatched = true;

  // going through the query tokens and seeing if they equal and
  // match up with the date format
  searchQueryTokens.forEach((queryToken, index) => {
    if (!_.includes(docDateTokens[index], queryToken)) {
      hasMatched = false;
    }
  });

  return hasMatched;
};

const getDateTokens = (date) => {
  let docDateTokens = date.split(DASH);

  return [docDateTokens[MONTH_INDEX], docDateTokens[DAY_INDEX], docDateTokens[YEAR_INDEX]];
};

export const doDatesMatch = (date, query) => {
  // move year to the end of the array to match
  // MM-DD-YYYY format
  const searchQueryTokens = parseQueryToTokens(query);
  const docDateTokens = getDateTokens(date);
  // removing falsy values from the array
  const cleanedQueryTokens = _.compact(searchQueryTokens);
  let hasMatched = false;

  // if the query is one word
  // check if the string contains the word.
  if (cleanedQueryTokens.length === SIZE_ONE) {
    hasMatched = _.includes(date, cleanedQueryTokens[0]);
  } else {
    hasMatched = doesQueryMatchDateTokens(docDateTokens, searchQueryTokens);
  }

  return hasMatched;
};
