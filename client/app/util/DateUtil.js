import React from 'react';
import StringUtil from './StringUtil';
import moment from 'moment';
import 'moment-timezone';
import _ from 'lodash';

const ZERO_INDEX_MONTH_OFFSET = 1;

export const dateFormatString = 'MM/DD/YYYY';

// Only Compatible to ISO Date/Time format
export const formatDate = function(dateString) {
  if (!dateString) {
    return;
  }

  let date = new Date(dateString);
  let month = StringUtil.leftPad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  let day = StringUtil.leftPad(date.getDate(), 2, '0');
  let year = date.getFullYear();

  return `${month}/${day}/${year}`;
};

export const formatArrayOfDateStrings = function(arrayOfDateStrings) {
  return arrayOfDateStrings.map((dateString) => {
    return formatDate(dateString);
  }).join(', ');
};

// Date format YYYY-MM-DD
export const formatDateStr = (dateString, dateFormat = 'YYYY-MM-DD', expectedFormat = dateFormatString) => {
  if (!dateString) {
    return;
  }

  return moment(dateString, dateFormat).format(expectedFormat);
};

export const DateString = ({ date, dateFormat = 'MM/DD/YY', inputFormat = 'YYYY-MM-DD', style }) => <span {...style}>
  {formatDateStr(date, inputFormat, dateFormat)}
</span>;

export const formatDateStringForApi = (dateString) => (
  formatDateStr(dateString, 'MM/DD/YYYY', 'YYYY-MM-DD')
);

const YEAR_INDEX = 0;
const MONTH_INDEX = 1;
const DAY_INDEX = 2;
const DASH = '-';
const SLASH = '/';

const parseQueryToTokens = (query = '') => {
  // date format passed in needs be in YYYY-MM-DD format
  // For example: 2016-06-12
  let searchQueryTokens = query.trim().toLowerCase().
    split(DASH);

  // no dashes exist in the query
  // tokenize using slashes
  if (!_.includes(query, DASH)) {
    searchQueryTokens = query.trim().toLowerCase().
      split(SLASH);
  }

  return searchQueryTokens;
};

const doesQueryMatchDateTokens = (docDateTokens, searchQueryTokens) => {
  let hasMatched = true;

  // going through the query tokens and seeing if they are equal and then
  // match them up with the date format
  searchQueryTokens.forEach((queryToken, index) => {
    if (!_.includes(docDateTokens[index], queryToken)) {
      hasMatched = false;
    }
  });

  return hasMatched;
};

const getDateTokens = (date) => {
  let docDateTokens = date.split(DASH);

  // move the year to the end of the array
  // to follow the MM/DD/YYYY format
  return [docDateTokens[MONTH_INDEX], docDateTokens[DAY_INDEX], docDateTokens[YEAR_INDEX]];
};

export const doDatesMatch = (date, query) => {
  // MM-DD-YYYY format
  const searchQueryTokens = parseQueryToTokens(query);
  const docDateTokens = date ? getDateTokens(date.toLowerCase()) : [];
  // removing falsy values from the array
  const cleanedQueryTokens = _.compact(searchQueryTokens);
  let hasMatched = false;

  // if the query is one word. i.e it doesn't contain a a dash or slash,
  // just check if the string contains the word.
  if (cleanedQueryTokens.length === 1) {
    hasMatched = _.includes(date, cleanedQueryTokens[0]);

  // otherwise do the query match to the date format
  } else {
    hasMatched = doesQueryMatchDateTokens(docDateTokens, searchQueryTokens);
  }

  return hasMatched;
};

export const getTimeWithoutTimeZone = (date, timeZone) => {
  return moment(date).tz(timeZone).
    format('H:mm');
};

export const getTime = (date) => {
  return moment(date).tz('America/New_York').
    format('h:mm a z').
    replace(/(\w)(DT|ST)/g, '$1T');
};

export const getTimeInDifferentTimeZone = (date, timeZone) => {
  return moment(date).tz(timeZone).
    format('h:mm a z').
    replace(/(\w)(DT|ST)/g, '$1T');
};

export const getDate = (date) => {
  return moment(date).format('YYYY-MM-DD');
};
