import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

import HEARING_TIME_OPTIONS from '../../../constants/HEARING_TIME_OPTIONS';
import SearchableDropdown from '../../components/SearchableDropdown';
import { formatTimeSlotLabel } from '../utils';

export const TimePicker = ({
  componentIndex,
  onChange,
  roTimezone,
  value,
}) => {

  // Okay, so a searchable dropdown with options like:
  // 8:30 AM Pacific Time (US & Canada) / 11:30 AM Eastern Time (US & Canada)
  // Values should have UTC offsets like this:
  // value: "08:30:00-07:00"
  const formatOptions = (zone, options) => {
    const formattedOptions = options.map((option) => {
      return {
        // We interpret the 'value' as being in roTimezone
        value: moment.tz(option.value, 'HH:mm', zone),
        // The label is the same as the label on the timeslots
        label: formatTimeSlotLabel(option.value, zone)
      };
    });

    return formattedOptions;
  };

  return (
    <SearchableDropdown
      name={`optionalHearingTime${componentIndex}`}
      label="Hearing Time"
      strongLabel
      placeholder="Select a time"
      options={formatOptions(roTimezone, HEARING_TIME_OPTIONS)}
      value={value}
      onChange={(option) => onChange(option ? option.value : null)}
    />
  );
};

TimePicker.defaultProps = { componentIndex: 0 };

TimePicker.propTypes = {
  componentIndex: PropTypes.number,
  onChange: PropTypes.func,
  roTimezone: PropTypes.string,
  value: PropTypes.string,
};
