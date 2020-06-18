import React from 'react';
import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES';
import HEARING_TIME_OPTIONS from '../../constants/HEARING_TIME_OPTIONS';
import moment from 'moment-timezone';
import _ from 'lodash';

import ExponentialPolling from '../components/ExponentialPolling';
import REGIONAL_OFFICE_INFORMATION from '../../constants/REGIONAL_OFFICE_INFORMATION';
import TIMEZONES from '../../constants/TIMEZONES';
import { COMMON_TIMEZONES } from '../constants/AppConstants';

export const isPreviouslyScheduledHearing = (hearing) =>
  hearing.disposition === HEARING_DISPOSITION_TYPES.postponed ||
  hearing.disposition === HEARING_DISPOSITION_TYPES.cancelled;

export const now = () => {
  return moment().
    tz(moment.tz.guess()).
    format('h:mm a');
};

export const getWorksheetAppealsAndIssues = (worksheet) => {
  const worksheetAppeals = _.keyBy(worksheet.appeals_ready_for_hearing, 'id');
  let worksheetIssues = _(worksheetAppeals).
    flatMap('worksheet_issues').
    keyBy('id').
    value();

  if (_.isEmpty(worksheetIssues)) {
    worksheetIssues = _.keyBy(worksheet.worksheet_issues, 'id');
  }

  const worksheetWithoutAppeals = _.omit(worksheet, ['appeals_ready_for_hearing']);

  return {
    worksheet: worksheetWithoutAppeals,
    worksheetAppeals,
    worksheetIssues
  };
};

export const sortHearings = (hearings) =>
  _.orderBy(Object.values(hearings || {}), (hearing) => hearing.scheduledFor, 'asc');

export const filterIssuesOnAppeal = (issues, appealId) =>
  _(issues).
    omitBy('_destroy').
    pickBy({ appeal_id: appealId }).
    value();

// assumes objects have identical properties
export const deepDiff = (firstObj, secondObj) => {
  const changedObject = _.reduce(
    firstObj,
    (result, firstVal, key) => {
      const secondVal = secondObj[key];

      if (_.isEqual(firstVal, secondVal)) {
        result[key] = null;
      } else if (_.isObject(firstVal) && _.isObject(secondVal)) {
        result[key] = deepDiff(firstVal, secondVal);
      } else {
        result[key] = secondVal;
      }

      return result;
    },
    {}
  );

  return _.pickBy(changedObject, (val) => val !== null);
};

export const filterCurrentIssues = (issues) =>
  _.omitBy(
    issues,
    (issue) =>
      // Omit if destroyed, or HAS NON-REMAND DISPOSITION FROM VACOLS
      /* eslint-disable no-underscore-dangle */
      issue._destroy || (issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols)
    /* eslint-enable no-underscore-dangle */
  );

export const filterPriorIssues = (issues) =>
  _.pickBy(
    issues,
    (issue) =>
      /* eslint-disable no-underscore-dangle */
      !issue._destroy && issue.disposition && !issue.disposition.includes('Remand') && issue.from_vacols
    /* eslint-enable no-underscore-dangle */
  );

export const VETERAN_TITLE = 'Veteran';
export const APPELLANT_TITLE = 'Appellant';

/**
 * Gets the title to use for the appellant of a hearing.
 * @param {object} hearing -- A hearing
 */
export const getAppellantTitleForHearing = (hearing) =>
  hearing?.appellantIsNotVeteran ? APPELLANT_TITLE : VETERAN_TITLE;

export const VIRTUAL_HEARING_HOST = 'host';
export const VIRTUAL_HEARING_GUEST = 'guest';

/**
 * Method to override falsy values for comparison
 * @param {*} init -- Initial value to compare against
 * @param {*} current -- Current Value to compare
 * @returns {boolean} -- Whether the object has been changed
 */
export const isEdited = (init, current) => {
  // Determine whether the initial value is falsy
  const falsy = init === null ? false : init;

  // Handle the value comparison
  switch (current) {
  // Empty strings should be treated the same as false and null
  case '':
  case false:
    return current != falsy;
    // Default to compare the initial with the current value
  default:
    return !_.isEqual(current, init);
  }
};

/**
 * Method to set edited fields
 * @param {Object} init -- Initial state of values
 * @param {Object} current -- Current state of values
 * @param {string[]} fields -- The list of fields being edited
 * @returns {Object} -- The edited boolean and the array of edited fields
 */
export const handleEdit = (init, current, fields) => {
  // Parse the value being changed
  return Object.keys(current).reduce((value, key) => {
    // Determine if the current value has been edited
    const edited = isEdited(init[key], current[key]);

    return {
      // Keep the initial value
      ...value,

      // Determine whether the form has been edited
      edited: value.edited || edited,

      // Set the changed fields
      editedFields: edited ? [...fields, key] : fields.filter((field) => field !== key)
    };
  }, {});
};

export const virtualHearingRoleForUser = (user, hearing) =>
  user.userCanAssignHearingSchedule || user.userId === hearing?.judgeId ? VIRTUAL_HEARING_HOST : VIRTUAL_HEARING_GUEST;

export const pollVirtualHearingData = (hearingId, onSuccess) => (
  // Did not specify retryCount so if api call fails, it'll stop polling.
  // If need to retry on failure, pass in retryCount
  <ExponentialPolling
    method="GET"
    interval={1000}
    onSuccess={onSuccess}
    render={() => null}
    url={`/hearings/${hearingId}/virtual_hearing_job_status`}
  />
);

/**
 * Method to reset the keys on an object
 * @param {Object} obj -- The object which is being reset
 * @returns {Object} -- New object with the same keys and empty values
 */
export const reset = (obj) => Object.keys(obj).reduce((result, item) => ({ ...result, [item]: '' }), {});

/**
 * Method to change the cancelled status if both objects are set to cancelled
 * @param {Object} first -- The first object to check status
 * @param {Object} second -- The second object to check status
 * @param {string} form -- The form to check the value of status
 * @returns {Object} -- The initial and current values that will be compared later
 */
export const toggleCancelled = (first, second, form) =>
  !second[form]?.requestCancelled && first[form]?.status === 'cancelled' ?
    {
      init: {
        ...first,
        [form]: reset(first[form])
      },
      current: {
        ...second,
        [form]: {
          ...second[form],
          requestCancelled: false
        }
      }
    } :
    {
      init: first,
      current: second
    };

/**
 * Method to calculate hearing details changes accounting for cancelled virtual hearings
 * @param {Object} init -- The initial form details
 * @param {Object} current -- The current form details
 */
export const getChanges = (first, second) => {
  // Handle cancelled status
  const { init, current } = toggleCancelled(first, second, 'virtualHearingForm');

  return deepDiff(init, current);
};

/**
 * Method to transform an object to a list of dropdown or radio options
 * @param {Object} object -- The object to turn into a list of options
 * @param {Object} noneOption -- The "None" option
 * @param {function} transformer -- Transforms the values of the object into options
 */
export const getOptionsFromObject = (object, noneOption, transformer) =>
  _.concat(_.map(_.values(object), transformer), [noneOption]);

/**
 * Method to get the Timezone label of a Timezone value
 * @param {string} tz -- Key of the Timezone to get the label
 * @returns {string} -- The label of the timezone
 */
export const zoneName = (name) => {
  // Filter the zone name
  const [zone] = Object.keys(TIMEZONES).filter((tz) => TIMEZONES[tz] === name);

  // Return the friendly zone name
  return zone;
};

/**
 * Method to add timezone to the label of the time
 * @returns {Array} -- List of hearing times with the zone appended to the label
 */
export const hearingTimeOptsWithZone = () =>
  HEARING_TIME_OPTIONS.map((time) => ({
    ...time,
    label: `${moment(time.label, 'h:mm A').format('h:mm A')} ${zoneName(COMMON_TIMEZONES[0])}`
  }));

/**
 * Returns the available timeTIMEZONES divided by common and the rest
 * @param {string} time -- String representation of the time to convert
 * @returns {Object} -- { options: [], commons: [] }
 */
export const timezones = (time) => {
  // Get the list of Unique Regional Office TimeTIMEZONES
  const ros = _.uniq(Object.keys(REGIONAL_OFFICE_INFORMATION).map((ro) => REGIONAL_OFFICE_INFORMATION[ro].timezone));

  // Convert the time into a date object
  const dateTime = moment(time, 'HH:mm').tz(COMMON_TIMEZONES[0]);

  // Map the available timeTIMEZONES to a select options object
  const options = Object.keys(TIMEZONES).map((zone) => ({
    value: TIMEZONES[zone],
    label: `${zone} (${moment(dateTime, 'HH:mm').
      tz(TIMEZONES[zone]).
      format('h:mm A')})`
  }));

  // Sort the common options by the common timeTIMEZONES
  const sortedOptions = options.
    // Sort the Regional Office timeTIMEZONES to the top
    sort((zone) => {
      if (ros.includes(zone.value)) {
        return -1;
      }

      return 1;
    }).
    // Sort the most common timeTIMEZONES to the very top
    sort((zone) => {
      if (COMMON_TIMEZONES.includes(zone.value)) {
        return -1;
      }

      return 1;
    });

  // Return the values and the count of commons
  return { options: sortedOptions, commonsCount: ros.length };
};
