import moment from 'moment-timezone';
import { times } from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
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

  // List starts at 0:00 and ends at 11:45 eastern
  // Set the label, option.value (time) is in eastern
  const generateTimes = (zone) => {
    const midnight = moment.tz('00:00', 'HH:mm', 'America/New_York');
    // 96 == 24hrs * (60min/4) == every fifteen minutes
    const options = times(96).map((index) => {
      const optionValue = midnight.clone().add(index * 15, 'minutes').
        format('HH:mm');

      return {
        value: optionValue,
        label: formatTimeSlotLabel(optionValue, zone)
      };
    });

    return options;
  };

  return (
    <SearchableDropdown
      name={`optionalHearingTime${componentIndex}`}
      hideLabel
      placeholder="Select a time"
      options={generateTimes(roTimezone)}
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
