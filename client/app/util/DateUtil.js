import React from 'react';
import StringUtil from './StringUtil';
import moment from 'moment-timezone';
import _ from 'lodash';

const ZERO_INDEX_MONTH_OFFSET = 1;

export const dateFormatString = 'MM/DD/YYYY';

// Only Compatible to ISO Date/Time format
export const formatDate = function(dateString) {
  if (!dateString) {
    return;
  }

  if (typeof dateString === 'string' && !dateString.match(/([+-][0-2]\d:[0-5]\d|Z)$/)) {
    throw new Error('Passing string without timezone -- try formatDateStr() instead');
  }

  const date = new Date(dateString);

  const month = StringUtil.leftPad(date.getMonth() + ZERO_INDEX_MONTH_OFFSET, 2, '0');
  const day = StringUtil.leftPad(date.getDate(), 2, '0');
  const year = date.getFullYear();

  return `${month}/${day}/${year}`;
};

// Date format YYYY-MM-DD
export const formatDateStr = (dateString, dateFormat = 'YYYY-MM-DD',
  expectedFormat = dateFormatString, forceUtc = false) => {
  if (!dateString) {
    return;
  }

  let dateStringFormat = dateFormat;

  // attempt to Do the Right Thing
  if (typeof dateString === 'string' && dateFormat === 'YYYY-MM-DD') {
    if (dateString.match(/^\d\d?\/\d\d?\/\d\d\d\d$/)) {
      dateStringFormat = 'MM/DD/YYYY';
    } else if (dateString.match(/^\d\d\d\d\//)) {
      dateStringFormat = 'YYYY/MM/DD';
    }
  }

  let date = moment(dateString, dateStringFormat);

  if (forceUtc) {
    date = date.utc();
  }

  return date.format(expectedFormat);
};

export const formatDateStrUtc = (dateString, expectedFormat = dateFormatString) => {
  return formatDateStr(dateString, null, expectedFormat, true);
};

export const formatArrayOfDateStrings = function(arrayOfDateStrings) {
  if (Array.isArray(arrayOfDateStrings)) {
    return arrayOfDateStrings.map((dateString) => {
      return formatDateStr(dateString);
    }).join(', ');
  }

  return '';

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

export const getDate = (date) => {
  return moment(date).format('YYYY-MM-DD');
};

export const getDisplayTime = (dateString, scheduledTimeString, timezone) => {
  const val = scheduledTimeString ? moment(scheduledTimeString, 'HH:mm a').format('h:mm A') : '';

  if (timezone) {
    const tz = moment(dateString).tz(timezone).
      format('z');

    return `${val} ${tz}`;
  }

  return val;
};

export const getMinutesToMilliseconds = (minutes) => {
  return minutes * 60 * 1000;
};

export const daysSinceAssigned = (task) => moment().startOf('day').
  diff(moment(task.assignedOn), 'days');

export const daysSincePlacedOnHold = (task) => moment().startOf('day').
  diff(task.placedOnHoldAt, 'days');
