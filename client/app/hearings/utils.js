/* eslint-disable camelcase */
import React from 'react';
import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES';
import moment from 'moment-timezone';
import _ from 'lodash';

import ExponentialPolling from '../components/ExponentialPolling';
import REGIONAL_OFFICE_INFORMATION from '../../constants/REGIONAL_OFFICE_INFORMATION';
// To see how values were determined: https://github.com/department-of-veterans-affairs/caseflow/pull/14556#discussion_r447102582
import TIMEZONES from '../../constants/TIMEZONES';
import { COMMON_TIMEZONES, REGIONAL_OFFICE_ZONE_ALIASES } from '../constants/AppConstants';
import ApiUtil from '../util/ApiUtil';
import { RESET_VIRTUAL_HEARING } from './contexts/HearingsFormContext';
import HEARING_REQUEST_TYPES from '../../constants/HEARING_REQUEST_TYPES';
import HEARING_DISPOSITION_TYPE_TO_LABEL_MAP from '../../constants/HEARING_DISPOSITION_TYPE_TO_LABEL_MAP';


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

  const worksheetWithoutAppeals = _.omit(worksheet, [
    'appeals_ready_for_hearing'
  ]);

  return {
    worksheet: worksheetWithoutAppeals,
    worksheetAppeals,
    worksheetIssues
  };
};

export const sortHearings = (hearings) =>
  _.orderBy(
    Object.values(hearings || {}),
    // Convert to EST before sorting, this timezeon doesn't effect what's displayed
    //   we just need to pick one so the sorting works correctly if hearings were
    //   scheduled in different time zones.
    (hearing) => moment.tz(hearing.scheduledFor, 'America/New_York'),
    'asc'
  );

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

      if (_.isObject(firstVal) && _.isObject(secondVal)) {
        const nestedDiff = deepDiff(firstVal, secondVal);

        if (nestedDiff && !_.isEmpty(nestedDiff)) {
          result[key] = nestedDiff;
        }
      } else if (!_.isEqual(firstVal, secondVal)) {
        result[key] = secondVal;
      }

      return result;
    },
    {}
  );

  return changedObject;
};

export const filterCurrentIssues = (issues) =>
  _.omitBy(
    issues,
    (issue) =>
      // Omit if destroyed, or HAS NON-REMAND DISPOSITION FROM VACOLS
      /* eslint-disable no-underscore-dangle */
      issue._destroy ||
      (issue.disposition &&
        !issue.disposition.includes('Remand') &&
        issue.from_vacols)
    /* eslint-enable no-underscore-dangle */
  );

export const filterPriorIssues = (issues) =>
  _.pickBy(
    issues,
    (issue) =>
      /* eslint-disable no-underscore-dangle */
      !issue._destroy &&
      issue.disposition &&
      !issue.disposition.includes('Remand') &&
      issue.from_vacols
    /* eslint-enable no-underscore-dangle */
  );

export const VETERAN_TITLE = 'Veteran';
export const APPELLANT_TITLE = 'Appellant';

/**
 * Gets the title to use for the appellant of a hearing.
 * @param {string} appellantIsNotVeteran -- bool
 */
export const getAppellantTitle = (appellantIsNotVeteran) =>
  appellantIsNotVeteran ? APPELLANT_TITLE : VETERAN_TITLE;

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
      editedFields: edited ?
        [...fields, key] :
        fields.filter((field) => field !== key)
    };
  }, {});
};

export const virtualHearingRoleForUser = (user, hearing) =>
  user.userCanAssignHearingSchedule || user.userId === hearing?.judgeId ?
    VIRTUAL_HEARING_HOST :
    VIRTUAL_HEARING_GUEST;

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
export const reset = (obj) =>
  Object.keys(obj).reduce((result, item) => ({ ...result, [item]: '' }), {});

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
  const { init, current } = toggleCancelled(first, second, 'virtualHearing');

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
 * @param {string} time -- The time to which the zone is being added
 * @param {string} name -- Name of the zone, defaults to New York
 * @returns {string} -- The label of the timezone
 */
export const zoneName = (time, name, format) => {
  // Default to using America/New_York
  const timezone = name ? name : COMMON_TIMEZONES[3];

  // Filter the zone name
  const [zone] = Object.keys(TIMEZONES).filter((tz) => TIMEZONES[tz] === timezone);

  // Set the label
  const label = format ? '' : zone;

  // Return the value if it is not a valid time
  return moment(time, 'h:mm A').isValid() ? `${moment(time, 'h:mm a').tz(timezone).
    format(`h:mm A ${format || ''}`)}${label}` : time;
};

/**
 * Method to add timezone to the label of the time
 * @returns {Array} -- List of hearing times with the zone appended to the label
 */
export const hearingTimeOptsWithZone = (options, local) =>
  options.map((item) => {
    // Default to using EST for all times before conversion
    moment.tz.setDefault(local === true ? 'America/New_York' : local);

    // Check which label to use
    const label = item.label ? 'label' : 'displayText';

    // Set the time
    const time = zoneName(item[label]);

    // Set the time in the local timezone
    const localTime = zoneName(item[label], local === true ? '' : local);

    return {
      ...item,
      [label]: local && localTime !== time ? `${localTime} / ${time}` : time
    };
  });

/**
 * Method to normalize the Regional Office Timezone names
 * @param {string} name -- Name of the Regional Office timezone
 */
export const getFriendlyZoneName = (name) => {
  // There is not a friendly name for some of the Regional Office zones, choose the city name instead for those
  return Object.keys(REGIONAL_OFFICE_ZONE_ALIASES).includes(name) ? REGIONAL_OFFICE_ZONE_ALIASES[name] : name;
};

/**
 * Method to return a list of Regional Office Timezones sorted with common timezones at the top
 * @returns {Array} -- List of Regional Office Timezones
 */
export const roTimezones = () =>
  _.uniq(
    Object.keys(REGIONAL_OFFICE_INFORMATION).map(
      (ro) => getFriendlyZoneName(REGIONAL_OFFICE_INFORMATION[ro].timezone)
    )
  );

/**
 * Returns the available timezones options and the count of the available Regional Office timezones
 * @param {string} time -- String representation of the time to convert
 * @returns {Object} -- { options: Array, commonsCount: number }
 */
export const timezones = (time) => {
  // Initialize count of common timezones
  let commonsCount = 0;

  // Get the list of Regional Office Timezones
  const ros = roTimezones();

  // Convert the time into a date object
  const dateTime = moment(time, 'HH:mm').tz(COMMON_TIMEZONES[0]);

  // Map the available timeTIMEZONES to a select options object
  const unorderedOptions = Object.keys(TIMEZONES).map((zone) => {
    // Default the index to be based on the timezone offset, add 100 to move below the Regional Office zones
    let index = Math.abs(moment.tz(TIMEZONES[zone]).utcOffset()) + 100;

    // Sort the most common timezones to the top followed by Regional Office timezones
    if (COMMON_TIMEZONES.includes(TIMEZONES[zone])) {
      // Increase the count of common timezones
      commonsCount += 1;

      // Inverse the index of the common zones to move EST to the top and move west
      index = -Math.abs(COMMON_TIMEZONES.indexOf(TIMEZONES[zone]));
    } else if (ros.includes(TIMEZONES[zone])) {
      // Divide the offset by 100 to move RO zones above the remaining zones
      index = Math.abs(moment.tz(TIMEZONES[zone]).utcOffset()) / 100;

      // Increase the count of common timezones
      commonsCount += 1;
    }

    // Return the formatted options
    return {
      index,
      value: TIMEZONES[zone],
      label: `${zone} (${moment(dateTime, 'HH:mm').
        tz(TIMEZONES[zone]).
        format('h:mm A')})`
    };
  });

  // Return the values and the count of commons
  const orderedOptions = _.orderBy(unorderedOptions, ['index']);

  // Add null option first to array of timezone options to allow deselecting timezone
  const options = [{ value: null, label: '' }, ...orderedOptions];

  return { options, commonsCount };
};

/**
 * Method to process alerts returned from the API
 * @param {Array} alerts -- List of alerts tod process
 * @param {Object} props -- Properties containing functions to receive alerts
 * @param {Function} poll -- Function to poll the API when alerts are asynchronous
 */
export const processAlerts = (alerts, props, poll) => alerts.map((alert) => {
  // Call the receive alerts function if there are hearing alerts
  if (alert?.hearing) {
    return props.onReceiveAlerts(alert.hearing);
  } else if (alert?.virtual_hearing && !_.isEmpty(alert.virtual_hearing)) {
    // Call the transition alerts function if there are virtual hearing alerts
    props.onReceiveTransitioningAlert(alert.virtual_hearing, 'virtualHearing');

    return poll(true);
  }

  // Default return the alert
  return alert;
});

/**
 * Method to poll the hearings endpoint and update virtual hearing details asynchronously
 * @param {object} hearing -- Hearing to poll against
 * @param {object} options -- Functions to handle state change based on new data
 */
export const startPolling = (hearing, { setShouldStartPolling, resetState, dispatch, props }) =>
  pollVirtualHearingData(hearing?.externalId, (response) => {
    // Parse the API response
    const resp = ApiUtil.convertToCamelCase(response);

    // Determine if we have finished creating the virtual hearing
    if (resp.virtualHearing.jobCompleted) {
      // Remove the polling state
      setShouldStartPolling(false);

      // Reset the state with the new details
      resetState();

      // Reset the Virtual Hearing State
      if (dispatch) {
        dispatch({ type: RESET_VIRTUAL_HEARING, payload: resp });
      }

      // Transition the alerts
      props.transitionAlert('virtualHearing');
    }

    // continue polling if return true (opposite of jobCompleted)
    return !resp.virtualHearing.jobCompleted;
  });

export const parseVirtualHearingErrors = (msg, hearing) => {
  // Remove the validation string from th error
  const messages = msg.split(':')[1];

  // Set inline errors for hearing conversion page
  return messages.split(',').reduce((list, message) => ({
    ...list,
    [(/Representative/).test(message) ? 'representativeEmail' : 'appellantEmail']:
       message.replace('Appellant', getAppellantTitle(hearing?.appellantIsNotVeteran))
  }), {});
};

export const regionalOfficeDetails = (key) => REGIONAL_OFFICE_INFORMATION[
  Object.keys(REGIONAL_OFFICE_INFORMATION).filter((roKey) => roKey === key)[0]
];

/**
 * Method to format the Hearing Change Request Type
 * @param {string} type -- The hearing request type label
 */
export const formatChangeRequestType = (type) => {
  switch (type) {
  case 'Virtual':
    return HEARING_REQUEST_TYPES.virtual;
  case 'Video':
    return HEARING_REQUEST_TYPES.video;
  case 'Central':
  default:
    return HEARING_REQUEST_TYPES.central;
  }
};

export const dispositionLabel = (disposition) => HEARING_DISPOSITION_TYPE_TO_LABEL_MAP[disposition] ?? 'None'

/* eslint-enable camelcase */
