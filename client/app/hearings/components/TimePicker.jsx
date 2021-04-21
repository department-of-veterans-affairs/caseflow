import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

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
      // This 'value' gets interpreted on save as roTimezone, though how that happens is complicated,
      // see hearing.rb::scheduled_for docs.
      // The point of this is so that for a west coast RO the dropdown starts at 8:15 pacific
      // rather than 8:15 eastern
      const correctedTime = moment.tz(option.value, 'HH:mm', roTimezone).tz('America/New_York').
        format('HH:mm');

      return {
        value: option.value,
        // The label is the same as the label on the timeslots
        label: formatTimeSlotLabel(correctedTime, zone)
      };
    });

    return formattedOptions;
  };

  return (
    <SearchableDropdown
      name={`optionalHearingTime${componentIndex}`}
      hideLabel
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
