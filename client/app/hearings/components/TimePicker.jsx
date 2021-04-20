import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

import HEARING_TIME_OPTIONS from '../../../constants/HEARING_TIME_OPTIONS';
import SearchableDropdown from '../../components/SearchableDropdown';

export const TimePicker = ({
  componentIndex,
  onChange,
  regionalOffice,
  value,
}) => {

  // Okay, so a searchable dropdown with options like:
  // 8:30 AM Pacific Time (US & Canada) / 11:30 AM Eastern Time (US & Canada)
  // Values should have UTC offsets like this:
  // value: "08:30:00-07:00"
  const formatOptions = (roTimezone, options) => {
    return options;
  };

  return (
    <SearchableDropdown
      name={`optionalHearingTime${componentIndex}`}
      label="Hearing Time"
      strongLabel
      placeholder="Select a time"
      options={formatOptions(regionalOffice?.timezone, HEARING_TIME_OPTIONS)}
      value={value}
      onChange={(option) => onChange(option ? option.value : null)}
    />
  );
};

TimePicker.defaultProps = { componentIndex: 0 };

TimePicker.propTypes = {
  componentIndex: PropTypes.number,
  onChange: PropTypes.func,
  regionalOffice: PropTypes.string,
  value: PropTypes.string,
};
