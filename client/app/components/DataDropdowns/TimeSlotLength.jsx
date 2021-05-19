import PropTypes from 'prop-types';
import React from 'react';

import SearchableDropdown from '../SearchableDropdown';
import { TIME_SLOT_LENGTHS } from './constants';

export const TimeSlotLength = (props) => {
  const {
    value,
    slotTimeLength,
    onChange,
    placeholder,
    errorMessage,
  } = props;

  return (
    <SearchableDropdown
      name="slotLengthMinutes"
      label="Length of Time Slots"
      strongLabel
      value={value}
      onChange={(option) => onChange(option?.value, option?.label)}
      options={TIME_SLOT_LENGTHS}
      errorMessage={slotTimeLength?.errorMsg || errorMessage}
      placeholder={placeholder}
    />
  );
};

TimeSlotLength.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  slotTimeLength: PropTypes.object,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
  onDropdownError: PropTypes.func,
  onFetchDropdownData: PropTypes.func,
  onReceiveDropdownData: PropTypes.func,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};
