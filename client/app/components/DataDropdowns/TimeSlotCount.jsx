import PropTypes from 'prop-types';
import React from 'react';
import { range } from 'lodash';

import SearchableDropdown from '../SearchableDropdown';

export const TimeSlotCount = ({ value, onChange }) => (
  <SearchableDropdown
    name="numberOfSlots"
    label="Number of Time Slots"
    strongLabel
    value={value}
    onChange={(option) => onChange(option?.value, option?.label)}
    options={range(1, 13).map((val) => ({ value: val, label: val }))}
  />
);

TimeSlotCount.propTypes = {
  value: PropTypes.oneOfType([
    PropTypes.number,
    PropTypes.object
  ]),
  onChange: PropTypes.func.isRequired,
};
