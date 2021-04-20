import PropTypes from 'prop-types';
import React from 'react';

import HEARING_TIME_OPTIONS from '../../../constants/HEARING_TIME_OPTIONS';
import SearchableDropdown from '../../components/SearchableDropdown';
import { formatTimeSlotLabel } from '../utils';

// A searchable dropdown with options like:
// 8:30 AM Pacific Time (US & Canada) / 11:30 AM Eastern Time (US & Canada)
export const TimePicker = ({
  componentIndex,
  onChange,
  roTimezone,
  value,
}) => {

  const formatOptions = (zone, options) => {
    const formattedOptions = options.map((option) => {
      return {
        // We interpret the 'value' as being in roTimezone by not changing it
        value: option.value,
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
      // This is responsible for updating the 'scheduledTimeString' which is in eastern
      // it is not responsible for updating what's selected in the dropdown
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
