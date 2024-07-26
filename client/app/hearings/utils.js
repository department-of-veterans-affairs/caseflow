/* eslint-disable camelcase */
import React from 'react';
import HEARING_DISPOSITION_TYPES from '../../constants/HEARING_DISPOSITION_TYPES';
import moment from 'moment-timezone';
import {
  findKey,
  flatMap,
  keyBy,
  isEmpty,
  omit,
  omitBy,
  orderBy,
  pickBy,
  reduce,
  isObject,
  isEqual,
  concat,
  uniq,
  times,
  compact,
  sortBy,
  get,
  map,
  isUndefined
} from 'lodash';

import HEARING_ROOMS_LIST from 'constants/HEARING_ROOMS_LIST';
import ExponentialPolling from '../components/ExponentialPolling';
import REGIONAL_OFFICE_INFORMATION from '../../constants/REGIONAL_OFFICE_INFORMATION';
// To see how values were determined: https://github.com/department-of-veterans-affairs/caseflow/pull/14556#discussion_r447102582
import TIMEZONES from '../../constants/TIMEZONES';
import { COMMON_TIMEZONES, REGIONAL_OFFICE_ZONE_ALIASES } from '../constants/AppConstants';
import {
  VIDEO_HEARING_LABEL,
  VIRTUAL_HEARING_LABEL,
  REQUEST_TYPE_OPTIONS
} from './constants';
import ApiUtil from '../util/ApiUtil';
import { RESET_VIRTUAL_HEARING } from './contexts/HearingsFormContext';
import HEARING_REQUEST_TYPES from '../../constants/HEARING_REQUEST_TYPES';
import HEARING_DISPOSITION_TYPE_TO_LABEL_MAP from '../../constants/HEARING_DISPOSITION_TYPE_TO_LABEL_MAP';
import COPY from '../../COPY.json';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

export const isPreviouslyScheduledHearing = (hearing) =>
  hearing?.disposition === HEARING_DISPOSITION_TYPES.postponed ||
  hearing?.disposition === HEARING_DISPOSITION_TYPES.cancelled;

export const now = () => {
  return moment().
    tz(moment.tz.guess()).
    format('h:mm a');
};

export const getWorksheetAppealsAndIssues = (worksheet) => {
  const worksheetAppeals = keyBy(worksheet.appeals_ready_for_hearing, 'id');
  let worksheetIssues = keyBy(flatMap(worksheetAppeals, 'worksheet_issues'), 'id');

  worksheetIssues = { ...worksheetIssues, ...keyBy(worksheet.worksheet_issues, 'id') };

  if (isEmpty(worksheetIssues)) {
    worksheetIssues = keyBy(worksheet.worksheet_issues, 'id');
  }

  const worksheetWithoutAppeals = omit(worksheet, [
    'appeals_ready_for_hearing'
  ]);

  return {
    worksheet: worksheetWithoutAppeals,
    worksheetAppeals,
    worksheetIssues
  };
};

export const sortHearings = (hearings) => {
  return orderBy(
    Object.values(hearings || {}),
    // Convert to EST before sorting, this timezeon doesn't effect what's displayed
    //   we just need to pick one so the sorting works correctly if hearings were
    //   scheduled in different time zones.
    (hearing) => moment.tz(hearing.scheduledFor, 'America/New_York'),
    'asc'
  );
};

export const filterIssuesOnAppeal = (issues, appealId) =>
  pickBy(omitBy(issues, '_destroy'), { appeal_id: appealId });

// assumes objects have identical properties
export const deepDiff = (firstObj, secondObj) => {
  const changedObject = reduce(
    firstObj,
    (result, firstVal, key) => {
      const secondVal = secondObj[key];

      if (isObject(firstVal) && isObject(secondVal)) {
        const nestedDiff = deepDiff(firstVal, secondVal);

        if (nestedDiff && !isEmpty(nestedDiff)) {
          result[key] = nestedDiff;
        }
      } else if (!isEqual(firstVal, secondVal)) {
        result[key] = secondVal;
      }

      return result;
    },
    {}
  );

  return changedObject;
};

export const filterCurrentIssues = (issues) =>
  omitBy(
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
  pickBy(
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

export const TIMEZONES_WITH_LUNCHBREAK = [
  'America/New_York', 'America/Chicago', 'America/Indiana/Indianapolis',
  'America/Kentucky/Louisville', 'America/Puerto_Rico'
];

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
    return !isEqual(current, init);
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

export const userJudgeOrCoordinator = (user) =>
  user.userIsJudge || user.userIsDvc || user.userIsHearingManagement || user.userIsBoardAttorney;

export const virtualHearingRoleForUser = (user, hearing) =>
  user.userCanAssignHearingSchedule || user.userId === hearing?.judgeId ?
    VIRTUAL_HEARING_HOST :
    VIRTUAL_HEARING_GUEST;

export const virtualHearingLinkLabelFull = (role) =>
  role === VIRTUAL_HEARING_HOST ?
    COPY.VLJ_VIRTUAL_HEARING_LINK_LABEL_FULL :
    COPY.REPRESENTATIVE_VIRTUAL_HEARING_LINK_LABEL;

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
 * Method to calculate hearing details changes accounting for hearings being converted to virtual
 * @param {Object} init -- The initial form details
 * @param {Object} current -- The current form details
 */
export const getConvertToVirtualChanges = (first, second) => {
  const diff = getChanges(first, second);

  // Always return emails and timezones whenever converting to virtual due to
  // field pre-population. Leave out emails if they're blank to prevent validation issues.
  return omitBy({
    ...diff,
    appellantTz: second.appellantTz,
    ...(second.appellantEmailAddress && { appellantEmailAddress: second.appellantEmailAddress }),
    representativeTz: second.representativeTz,
    ...(second.representativeEmailAddress && { representativeEmailAddress: second.representativeEmailAddress })
  }, isUndefined);
};

/**
 * Method to transform an object to a list of dropdown or radio options
 * @param {Object} object -- The object to turn into a list of options
 * @param {Object} noneOption -- The "None" option
 * @param {function} transformer -- Transforms the values of the object into options
 */
export const getOptionsFromObject = (object, noneOption, transformer) =>
  concat(map(Object.values(object), transformer), [noneOption]);

/**
 * Method to normalize the Regional Office Timezone names
 * @param {string} name -- Name of the Regional Office timezone
 */
export const getFriendlyZoneName = (name) => {
  // There is not a friendly name for some of the Regional Office zones, choose the city name instead for those
  return Object.keys(REGIONAL_OFFICE_ZONE_ALIASES).includes(name) ? REGIONAL_OFFICE_ZONE_ALIASES[name] : name;
};

/**
 * Method to get the Timezone label of a Timezone value
 * @param {string} time -- The time to which the zone is being added
 * @param {string} name -- Name of the zone, defaults to New York
 * @returns {string} -- The label of the timezone
 */
export const zoneName = (time, name, format) => {
  // Default to using America/New_York
  const timezone = name ? getFriendlyZoneName(name) : COMMON_TIMEZONES[3];

  // Filter the zone name
  const [zone] = Object.keys(TIMEZONES).filter((tz) => TIMEZONES[tz] === timezone);

  // Set the label
  const label = format ? '' : zone;

  // Return the value if it is not a valid time
  return moment(time, 'h:mm A').isValid() ? `${moment(time, 'h:mm a').tz(timezone).
    format(`h:mm A ${format || ''}`)}${label}` : time;
};

/**
 * Method to get short zone label from like 'Eastern' or 'Pacific'
 * @param {string} name -- Name of the zone, defaults to 'America/New_York'
 * @returns {string} -- The short label of the timezone
 */
export const shortZoneName = (name) => {
  const timezone = name ? getFriendlyZoneName(name) : COMMON_TIMEZONES[3];
  const zoneName = Object.keys(TIMEZONES).filter((tz) => TIMEZONES[tz] === timezone)[0];

  return zoneName?.split('Time')[0]?.trim();
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

    // This fixes some timezone bugs in the TimeSlot component, moment.tz.setDefault changes
    // -global- settings for moment.
    // This should definitely be removed, but that's only safe if the above call to setDefault
    // can also be removed.
    moment.tz.setDefault();

    return {
      ...item,
      [label]: local && localTime !== time ? `${localTime} / ${time}` : time
    };
  });

/**
 * Method to return a list of Regional Office Timezones sorted with common timezones at the top
 * @returns {Array} -- List of Regional Office Timezones
 */
export const roTimezones = () =>
  uniq(
    Object.keys(REGIONAL_OFFICE_INFORMATION).map(
      (ro) => getFriendlyZoneName(REGIONAL_OFFICE_INFORMATION[ro].timezone)
    )
  );

/**
 * Returns the available timezones options and the count of the available Regional Office timezones
 * @param {string} time -- String representation of the time to convert
 * @param {string} roTimezone -- String representation of the timezone of the RO selected
 * @returns {Object} -- { options: Array, commonsCount: number }
 */
export const timezones = (time, roTimezone) => {
  // Initialize count of common timezones
  let commonsCount = 0;

  // Get the list of Regional Office Timezones
  const ros = roTimezones();

  // Convert the time into a date object with the RO timezone
  const dateTime = moment.tz(time, 'HH:mm', roTimezone);

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

    // ensure that before the user selects a time it won't display 'Invalid Date' next to zone
    const zoneLabel = dateTime.isValid() ? `${zone} (${moment(dateTime, 'HH:mm').tz(TIMEZONES[zone]).
      format('h:mm A')})` : `${zone}`;

    // Return the formatted options
    return {
      index,
      value: TIMEZONES[zone],
      label: zoneLabel
    };
  });

  // Return the values and the count of commons
  const orderedOptions = orderBy(unorderedOptions, ['index']);

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
  } else if (alert?.virtual_hearing && !isEmpty(alert.virtual_hearing)) {
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
  const messages = msg.split(':')[2];

  // Set inline errors for hearing conversion page
  return messages.split(',').reduce((list, message) => ({
    ...list,
    [(/Representative/).test(message) ? 'representativeEmailAddress' : 'appellantEmailAddress']:
       message.replace('Appellant', getAppellantTitle(hearing?.appellantIsNotVeteran))
  }), {});
};

export const regionalOfficeDetails = (key) => REGIONAL_OFFICE_INFORMATION[
  Object.keys(REGIONAL_OFFICE_INFORMATION).filter((roKey) => roKey === key)[0]
];

/**
 * Method to return the full name of the appellant depending on whether it is the Veteran or not
 * @param {object} hearing -- Hearing values used to return the appellant name
 */
export const appellantFullName = ({
  appellantIsNotVeteran,
  appellantFirstName,
  appellantLastName,
  veteranFirstName,
  veteranLastName
}) => appellantIsNotVeteran ? `${appellantFirstName} ${appellantLastName}` : `${veteranFirstName} ${veteranLastName}`;

/**
 * Method to construct the task payload
 * @param {object} values -- The payload values to send to the backend
 * @param {object} task -- Additional details about the task
 */
export const taskPayload = (values, task = {}) => ({
  data: {
    task: {
      ...task,
      business_payloads: {
        values
      },
    },
  },
});

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

export const dispositionLabel = (disposition) => HEARING_DISPOSITION_TYPE_TO_LABEL_MAP[disposition] ?? 'None';

/**
 * Method to calculate an array of available time slots, no filled timeslots or hearings are included
 * @param {string} numberOfSlots  -- Max number of slots to generate
 * @param {string} beginsAt  -- Time of first possible slot in "America/New_York" timezone
 * @param {string} roTimezone -- Timezone like 'America/Los_Angeles' of the ro
 * @param {array} hearings    -- List of hearings scheduled for a specific date
 **/
const calculateAvailableTimeslots = ({
  numberOfSlots,
  beginsAt,
  roTimezone,
  scheduledHearings,
  slotLengthMinutes,
  lunchBreak
}) => {
  // Extract the hearing time, add the hearing_day date from beginsAt, set the timezone be the ro timezone
  const hearingTimes = scheduledHearings.map((hearing) => {
    const [hearingHour, hearingMinute] = hearing.hearingTime.split(':');
    const hearingTimeMoment = beginsAt.clone().set({ hour: hearingHour, minute: hearingMinute });

    // Change which zone the time is in but don't convert, "08:15 EDT" -> "08:15 PDT"
    return hearingTimeMoment.tz(roTimezone, true);
  });

  // Loop numberOfSlots number of times
  const availableSlots = times(numberOfSlots).map((index) => {
    // Create the possible time by adding our offset * slotLengthMinutes to beginsAt
    const possibleTime = beginsAt.clone().add(index * slotLengthMinutes, 'minutes');

    // If slot is after the lunch break, move it forward by the length of the break
    if (lunchBreak) {
      // Set the constants for lunch breaks
      const LUNCH_TIME = { hour: '12', minute: '30', lengthInMinutes: '30' };

      // Get the lunchbreak moment on the correct date
      const lunchBreakMoment = beginsAt.clone().tz(roTimezone).
        set({ hour: LUNCH_TIME.hour, minute: LUNCH_TIME.hour });

      if (possibleTime.isSameOrAfter(lunchBreakMoment)) {
        possibleTime.add(LUNCH_TIME.lengthInMinutes, 'minutes');
      }
    }

    // This slot is not available (full) if there's a scheduled hearing less than an hour before
    // or after the slot.
    // A 10:45 appointment will:
    // - Hide a 10:30 slot (it's full, so we return null)
    // - Hide a 11:30 slot (it's full, so we return null)
    const hearingWithinHourOfSlot = hearingTimes.some((scheduledHearingTime) =>
      (Math.abs(possibleTime.diff(scheduledHearingTime, 'minutes')) < slotLengthMinutes)
    );

    // Combine all the conditions that make a slot unavailable
    const slotIsUnavailable = hearingWithinHourOfSlot;

    // Return null if there is a filled time slot, otherwise return the hearingTime
    return slotIsUnavailable ? null : {
      slotId: index,
      time: possibleTime,
    };
  });

  return compact(availableSlots);
};

/**
 * Method to convert all timezones to 'America/New_York, add an id for React, and
 * combine the available slots and hearings
 * @param {string} roTimezone        -- Like "America/Los_Angeles"
 * @param {string} availableSlots    -- Array of unfilled slots
 * @param {string} scheduledHearings -- Array of hearings
 **/
const combineSlotsAndHearings = ({ roTimezone, availableSlots, scheduledHearings, hearingDayDate }) => {
  const slots = availableSlots.map((slot) => ({
    ...slot,
    key: `${slot?.slotId}-${slot?.time_string}`,
    full: false,
    // This is a moment object, always in "America/New_York"
    hearingTime: slot.time.format('HH:mm')
  }));

  const formattedHearings = scheduledHearings.map((hearing) => {
    const time = moment.tz(`${hearing?.hearingTime} ${hearingDayDate}`, 'HH:mm YYYY-MM-DD', roTimezone).clone().
      tz('America/New_York');

    return {
      ...hearing,
      key: hearing?.externalId,
      full: true,
      // Include this because slots have it and we use it for filtering
      time,
      // The hearingTime is in roTimezone, but it looks like "09:30", this takes that "09:30"
      // in roTimezone, and converts it to Eastern zone because slots are always in eastern.
      hearingTime: time.format('HH:mm')
    };
  });

  const slotsAndHearings = slots.concat(formattedHearings);

  // Sort by unix time
  return sortBy(slotsAndHearings, [(item) => item.time.format('x')]);

};

/**
 * Method to set the available time slots based on the hearings scheduled
 * @param {array} selectedTimeString -- List of hearings scheduled for a specific date
 * @param {array} slotsAndHearings   -- The ro id, can be RXX, C, or V
 */
const displaySelectedTimeAsSlot = ({ selected, slotsAndHearings }) => {
  if (!selected) {
    return slotsAndHearings;
  }

  // If a slot for this time already exists, it will be selected, don't add anything
  if (slotsAndHearings.find((item) => item.time.isSame(selected))) {
    return slotsAndHearings;
  }
  const timeString = selected?.tz('America/New_York')?.format('HH:mm');

  // Create a timeslot object (same as in combineSlotsAndHearings)
  const selectedTimeSlot = {
    slotId: 'selected-time',
    key: `selected-time-${timeString}`,
    full: false,
    hearingTime: timeString,
    time: selected,
  };

  // Figure out where to insert that timeslot object in existing slots/hearings array
  const foundIndex = slotsAndHearings.findIndex((item) => {
    return item.time.isAfter(selected);
  });
  // foundIndex is -1 when the slot should be last in the array
  const insertIndex = foundIndex === -1 ? slotsAndHearings.length : foundIndex;

  // Insert the timeslot object and return the new array
  slotsAndHearings.splice(insertIndex, 0, selectedTimeSlot);

  return slotsAndHearings;
};

/**
 * Method to set the available time slots based on the hearings scheduled
 * @param {array} scheduledHearingsList  -- List of hearings scheduled for a specific date
 * @param {string} ro         -- The ro id, can be RXX, C, or V
 * @param {string} roTimezone -- Like "America/Los_Angeles"
 *
 * The 'hearingTime' in the returned array is always in 'America/New_York' timezone.
 *
 * Each hearing passed in has a hearingTime property:
 * - This time is in the timezone of the ro that this individual hearing has in the db.
 * - hearingTime is a string like '09:45'
 * - It is generated by HearingTimeService::scheduled_time_string
 */
export const setTimeSlots = ({
  scheduledHearingsList,
  ro,
  roTimezone = 'America/New_York',
  beginsAt,
  numberOfSlots,
  slotLengthMinutes,
  lunchBreak = false,
  selected,
  hearingDayDate
}) => {
  // Safe assign the hearings array in case there are no scheduled hearings
  const scheduledHearings = scheduledHearingsList || [];

  const defaultNumberOfSlots = 8;
  const defaultBeginsAt = ro === 'C' ? '09:00' : '08:30';
  const momentDefaultBeginsAt = moment.tz(`${defaultBeginsAt} ${hearingDayDate}`, 'HH:mm YYYY-MM-DD', 'America/New_York');
  const momentBeginsAt = moment(beginsAt).tz('America/New_York');

  const defaultSlotLengthMinutes = 60;

  const availableSlots = calculateAvailableTimeslots({
    numberOfSlots: numberOfSlots || defaultNumberOfSlots,
    slotLengthMinutes: slotLengthMinutes || defaultSlotLengthMinutes,
    beginsAt: beginsAt ? momentBeginsAt : momentDefaultBeginsAt,
    roTimezone,
    scheduledHearings,
    lunchBreak
  });

  const slotsAndHearings = combineSlotsAndHearings({
    roTimezone,
    availableSlots,
    scheduledHearings,
    hearingDayDate
  });

  return displaySelectedTimeAsSlot({ selected, slotsAndHearings });

};

export const formatTimeSlotLabel = (time, zone) => {
  const timeFormatString = 'h:mm A z';
  const coTime = moment.tz(time, 'HH:mm', 'America/New_York').format(timeFormatString);
  const roTime = moment.tz(time, 'HH:mm', 'America/New_York').tz(zone).
    format(timeFormatString);

  if (roTime === coTime) {
    return coTime;
  }

  return `${roTime} (${coTime})`;
};

// Given the hearingType, if it starts with 'video' return Video or the
// passed in hearintType
export const formatHearingType = (hearingType) => {
  if (hearingType.toLowerCase().startsWith('video')) {
    return VIDEO_HEARING_LABEL;
  }

  return hearingType;
};

// Given a hearing day, return the judges last, first or ''
export const vljFullnameOrEmptyString = (hearingDay) => {
  const first = hearingDay?.judgeFirstName;
  const last = hearingDay?.judgeLastName;

  if (last && first) {
    return `VLJ ${last}, ${first}`;
  }

  return '';
};

// Make a string like "2 of 12" given a hearing day:
// - 2 is 'filledSlots' which comes from HearingDay
// - 12 is the 'totalSlots' which comes from HearingDay and depends on ro
export const formatSlotRatio = (hearingDay) => {
  const filledSlots = get(hearingDay, 'filledSlots', 0);
  const totalSlotCount = get(hearingDay, 'totalSlots', 0);
  const formattedSlotRatio = `${filledSlots} of ${totalSlotCount}`;

  return formattedSlotRatio;
};

// Check if there's a judge assigned
export const hearingDayHasJudge = (hearingDay) => hearingDay.judgeFirstName && hearingDay.judgeLastName;
// Check if there's a room assigned (there never is for virtual)
const hearingDayHasRoom = (hearingDay) => Boolean(hearingDay.room);
// Check if there's a judge or room assigned
const hearingDayHasJudgeOrRoom = (hearingDay) => hearingDayHasJudge(hearingDay) || hearingDayHasRoom(hearingDay);

// Make the '·' separator appear or disappear
export const separatorIfJudgeOrRoomPresent = (hearingDay) => hearingDayHasJudgeOrRoom(hearingDay) ? '·' : '';
// This is necessecary otherwise 'null' is displayed when there's no room or judge
export const hearingRoomOrEmptyString = (hearingDay) => hearingDay.room ? hearingDay.room : '';

/**
 * Method to group an object of days by month/year
 * @param {Object} days -- List of days to group
 */
export const groupHearingDays = (days) => Object.values(days).reduce((list, day) => {
  // Set the key to be the full month name and full year
  const key = moment(day.scheduledFor).format('MMMM YYYY');

  return {
    ...list,
    [key]: [...(list[key] || []), day]
  };
}, {});

/**
 * Curry function to attach the hearing day select GA event
 * @param {func} cb -- Callback function to run after sending the GA event
 */
export const selectHearingDayEvent = (cb) => (hearingDay) => {
  // Convert the date string into a moment object
  const date = moment(hearingDay.scheduledFor).startOf('day');

  // Take the absolute value of the difference using the start of day to be consistent regardless of user time
  const diff = Math.abs(moment().startOf('day').
    diff(date, 'days'));

  // Send the analytics event
  window.analyticsEvent(
    // Category
    'Hearings',
    // Action
    'Available Hearing Days – Select',
    // Label
    '',
    // Value
    `${diff} days between selected hearing day and today`
  );

  // Change the hearing day to the selected hearing day
  cb(hearingDay);
};

// Get an array with every fifteen minute increment in a day
// [00:00, 00:15, ... , 23:45]
const generateTimes = (roTimezone, date, intervalMinutes = 15) => {
  // Start at midnight '00:00' is the first minute of a day
  const currentTime = moment.tz(`${date} 00:00`, 'YYYY-MM-DD HH:mm', roTimezone);
  // End at 23:59, the last minute of a day
  const elevenFiftyNine = moment.tz(`${date} 23:59`, 'YYYY-MM-DD HH:mm', roTimezone);

  const times = [];

  // Go through the day in fifteen minute increments and store each increment
  while (currentTime.isBefore(elevenFiftyNine)) {
    // Moment has mutable objects so clone() is necessary
    times.push(currentTime.clone());
    currentTime.add(intervalMinutes, 'minute');
  }

  return times;
};

// Move the part of the arrawy after newFirstValue to the end of the array
const moveTimesToEndOfArray = (newFirstValue, times) => {
  // Find the index of newFirstValue
  const firstValueIndex = times.findIndex((time) => time.isSame(newFirstValue));

  // Remove all values before newFirstValue from the front of the array
  const beforeFirstValue = times.slice(0, firstValueIndex);
  const afterFirstValue = times.slice(firstValueIndex);

  // Add the values back onto the end of the array
  return afterFirstValue.concat(beforeFirstValue);
};
// Convert each time in the array into the expected 'option' format for react-select
const formatTimesToOptionObjects = (times) => {
  return times.map((time) => {
    return {
      label: time.format('h:mm A'),
      value: time
    };
  });
};

// Generate a time for every 15m increment in a day.
// Then move every time before beginsAt to the end of
// the array to beginsAt appears first.
export const generateOrderedTimeOptions = (roTimezone, hearingDayDate) => {
  const beginsAt = moment.tz(`${hearingDayDate} 08:30`, 'YYYY-MM-DD HH:mm', roTimezone);
  const times = generateTimes(roTimezone, hearingDayDate);
  const reorderedTimes = moveTimesToEndOfArray(beginsAt, times);
  const options = formatTimesToOptionObjects(reorderedTimes);

  return options;
};

// Checks if the input matches the hour of a candidate.value which is a moment object
const matchesHour = (candidate, input, exact = false) => {
  const candidateHourString = candidate.value.format('h');

  return exact ? candidateHourString === input : candidateHourString.startsWith(input);
};
const removeOneLeadingZero = (string) => {
  return string[0] === '0' ? string.slice(1) : string;
};
// Checks if the input matches any part of a candidate.value which is a moment object
const matchesAny = (candidate, input) => {
  if (input.includes(':')) {
    // Split into hours and minutes
    const [hour, minutesAndAmPm] = input.split(':');

    // Check that the hour matches exactly and the minutes+ampm are present
    return matchesHour(candidate, hour, true) && matchesAny(candidate, minutesAndAmPm);
  }
  if (!input.includes(':')) {
    // Produce a time like '400pm' or '800am' for string searching
    const candidateNoColon = candidate.value.format('hhmmA');
    // Remove spaces, force upper case so AM/PM searching works
    const noColonOrSpaces = input.replace(' ', '').toUpperCase();
    // Remove a leading zero if there is one
    const noLeadingZero = removeOneLeadingZero(noColonOrSpaces);

    return candidateNoColon.includes(noLeadingZero);
  }
};

// Filter the options list to display only options that match
// what's been typed into the input
export const filterOptions = (candidate, input) => {
  // If only one character in the input assume it represents an hour
  if (input.length === 1) {
    return matchesHour(candidate, input);
  }
  // If one character and ':' in the input assume it represents an hour
  if (input.length === 2 && input.endsWith(':')) {
    return matchesHour(candidate, input[0], true);
  }
  // For everything else, send to matchesAny, which also handles ':'
  if (input.length >= 2) {
    return matchesAny(candidate, input);
  }
};

// Given a long timezone like "America/Los_Angeles" return the
// short version like "PDT" or "PST" (depending on date)
export const getTimezoneAbbreviation = (timezone) => {
  // Create a moment object so we can extract the timezone
  // abbreviation like 'PDT'
  return moment.tz('00:00', 'HH:mm', timezone).format('z');
};

export const formatNotificationLabel = (hearing, virtual, appellantTitle) => {
  const poaLabel = virtual ? ', POA,' : ' and POA';
  const recipientLabel = hearing?.representative ? `${appellantTitle}${poaLabel}` : `${appellantTitle}`;

  if (virtual) {
    return `When you schedule the hearing, the ${recipientLabel} and ` +
     'Judge will receive an email with connection information for the virtual hearing.';
  }

  return `The ${recipientLabel} will receive email reminders 7 and 3 days before the hearing. ` +
    'Caseflow won’t send notifications immediately after scheduling.';
};

export const docketTypes = (originalType) => {
  const [option] = REQUEST_TYPE_OPTIONS.filter((type) => type.value === originalType);

  return [
    option,
    {
      value: HEARING_REQUEST_TYPES.virtual,
      label: VIRTUAL_HEARING_LABEL
    }
  ];
};

export const readableDocketType = (docketType) =>
  REQUEST_TYPE_OPTIONS.find((type) => docketType === type.value || docketType?.value === type.value);

export const getRegionalOffice = (roKey) => {
  if (!roKey) {
    return {
      timezone: COMMON_TIMEZONES[0],
      key: 'C',
    };
  }

  return ({
    ...REGIONAL_OFFICE_INFORMATION[roKey],
    key: roKey
  });
};

const virtualHearingOption = {
  value: true,
  label: VIRTUAL_HEARING_LABEL
};

export const allScheduleVeteranDropdownOptions = (readableHearingRequestType, readableOriginalHearingRequestType) => {
  if (readableHearingRequestType === 'Virtual') {
    return [{ value: false, label: readableOriginalHearingRequestType }, virtualHearingOption];
  }

  return [{ value: false, label: readableHearingRequestType }, virtualHearingOption];
};

export const allDetailsDropdownOptions = (hearing) => {
  return [{ value: false, label: hearing?.readableRequestType }, virtualHearingOption];
};

export const hearingRequestTypeCurrentOption = (options, virtualHearing) => {
  if (!virtualHearing || !virtualHearing?.status || virtualHearing?.status === 'cancelled') {
    return options[0];
  }

  return options[1];
};

export const hearingRequestTypeOptions = (allOptions, currentOption) => {
  return allOptions.filter((opt) => opt.label !== currentOption.label);
};

export const formatRoomOption = (room) => {
  const option = findKey(HEARING_ROOMS_LIST, { label: room });

  return ({
    label: option ? HEARING_ROOMS_LIST[option.toString()].label : 'None',
    value: option ? option.toString() : null
  });
};

export const columnsForUser = (user, columns) => {
  if (user.userVsoEmployee) {
    const omitColumnsNames = ['VLJ'];

    return columns.filter((column) => !omitColumnsNames.includes(column.name));
  }

  return columns;
};

export const headersforUser = (user, headers) => {
  if (user.userVsoEmployee) {
    const omitHeadersLabels = ['VLJ', 'CSS ID'];

    return headers.filter((header) => !omitHeadersLabels.includes(header.label));
  }

  return headers;
};

const isVirtualHearingJobCompleted = (hearing) =>
  (hearing?.isVirtual && !hearing?.virtualHearing?.jobCompleted);

export const readOnlyEmails = (hearing) => {
  return isVirtualHearingJobCompleted(hearing) || hearing?.scheduledForIsPast;
};

export const formatVljName = (lastName, firstName) => {
  if (lastName && firstName) {
    return `${lastName}, ${firstName}`;
  }
};

export const scheduleData = ({ hearingSchedule, user }) => {
  const rows = orderBy(hearingSchedule, (hearingDay) => hearingDay.scheduledFor, 'asc').
    map((hearingDay) => ({
      id: hearingDay.id,
      scheduledFor: hearingDay.scheduledFor,
      readableRequestType: hearingDay.readableRequestType,
      regionalOffice: hearingDay.regionalOffice,
      room: hearingDay.room,
      judgeCssId: hearingDay.judgeCssId,
      vlj: formatVljName(hearingDay.judgeLastName, hearingDay.judgeFirstName),
      hearingsScheduled: hearingDay.filledSlots
    }));

  const columnData = [
    {
      header: 'Date',
      name: 'Date',
      align: 'left',
      valueName: 'scheduledFor',
      columnName: 'date',
      valueFunction: (row) => <Link ariaLabel={`schedule docket ${row.id}`} to={`/schedule/docket/${row.id}`}>
        {moment(row.scheduledFor).format('ddd M/DD/YYYY')}
      </Link>,
      getSortValue: (row) => {
        return row.scheduledFor;
      }
    },
    {
      header: 'Type',
      name: 'Type',
      cellClass: 'type-column',
      align: 'left',
      tableData: rows,
      enableFilter: true,
      filterValueTransform: formatHearingType,
      anyFiltersAreSet: true,
      label: 'Filter by type',
      columnName: 'readableRequestType',
      valueName: 'Hearing Type',
      valueFunction: (row) => row.readableRequestType
    },
    {
      header: 'Regional Office',
      name: 'Regional Office',
      tableData: rows,
      enableFilter: true,
      anyFiltersAreSet: true,
      enableFilterTextTransform: false,
      label: 'Filter by RO',
      columnName: 'regionalOffice',
      valueName: 'regionalOffice'
    },
    {
      header: 'Room',
      name: 'Room',
      align: 'left',
      valueName: 'room',
      columnName: 'room',
      tableData: rows,
      getSortValue: (hearingDay) => {
        return hearingDay.room;
      }
    },
    {
      header: 'VLJ',
      name: 'VLJ',
      align: 'left',
      tableData: rows,
      enableFilter: true,
      anyFiltersAreSet: true,
      label: 'Filter by VLJ',
      columnName: 'vlj',
      valueName: 'vlj'
    },
    {
      header: 'Hearings Scheduled',
      name: 'Hearings Scheduled',
      align: 'left',
      tableData: rows,
      columnName: 'hearingsScheduled',
      valueName: 'hearingsScheduled'
    }
  ];

  const columns = columnsForUser(user, columnData);

  const exportHeaders = [
    { label: 'ID',
      key: 'id' },
    { label: 'Scheduled For',
      key: 'scheduledFor' },
    { label: 'Type',
      key: 'readableRequestType' },
    { label: 'Regional Office',
      key: 'regionalOffice' },
    { label: 'Room',
      key: 'room' },
    { label: 'CSS ID',
      key: 'judgeCssId' },
    { label: 'VLJ',
      key: 'vlj' },
    { label: 'Hearings Scheduled',
      key: 'hearingsScheduled' }
  ];

  const headers = headersforUser(user, exportHeaders);

  return { headers, rows, columns };
};

/* eslint-enable camelcase */
