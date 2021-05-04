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

  // Set the label, option.value (time) is in eastern
  const formatOptions = (zone, options) => {
    return options.map((option) => {
      return {
        value: option.value,
        label: formatTimeSlotLabel(option.value, zone)
      };
    });
  };

  return (
    <SearchableDropdown
      name={`optionalHearingTime${componentIndex}`}
      hideLabel
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
