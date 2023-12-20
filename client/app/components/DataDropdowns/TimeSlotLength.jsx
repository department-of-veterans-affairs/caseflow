import PropTypes from 'prop-types';
import React from 'react';

import SearchableDropdown from '../SearchableDropdown';
import { TIME_SLOT_LENGTHS } from './constants';

export const TimeSlotLength = ({ value, onChange }) => (
  <SearchableDropdown
    name="slotLengthMinutes"
    label="Length of Time Slots"
    strongLabel
    value={value}
    onChange={(option) => onChange(option?.value, option?.label)}
    options={TIME_SLOT_LENGTHS}
  />
);

TimeSlotLength.propTypes = {
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
};
