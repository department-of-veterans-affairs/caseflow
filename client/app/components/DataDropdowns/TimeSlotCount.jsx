import PropTypes from 'prop-types';
import React from 'react';
import { range } from 'lodash';

import SearchableDropdown from '../SearchableDropdown';

export const TimeSlotCount = (props) => {
  const {
    value,
    slotTimeLength,
    onChange,
    placeholder,
    errorMessage,
  } = props;

  return (
    <SearchableDropdown
      name="numberOfSlots"
      label="Number of Time Slots"
      strongLabel
      value={value}
      onChange={(option) => onChange(option?.value, option?.label)}
      options={range(1, 13).map((val) => ({ value: val, label: val }))}
      errorMessage={slotTimeLength?.errorMsg || errorMessage}
      placeholder={placeholder}
    />
  );
};

TimeSlotCount.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  slotTimeLength: PropTypes.object,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};
