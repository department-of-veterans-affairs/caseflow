import React from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../../../components/SearchableDropdown';
import { timezones } from '../../../utils';
import { timezoneDropdownStyles, timezoneStyles } from '../style';

export const Timezone = ({ readOnly, value, errorMessage, onChange, time }) => {
  const { options, commonsCount } = timezones(time);

  return (
    <SearchableDropdown
      styling={timezoneStyles(commonsCount)}
      dropdownStyling={timezoneDropdownStyles(commonsCount)}
      name="Timezone"
      readOnly={readOnly}
      placeholder="Select a timezone"
      options={options}
      value={value}
      onChange={(option) => onChange(option ? option.value : null)}
      errorMessage={errorMessage}
      strongLabel
    />
  );
};

Timezone.defaultProps = {
  value: null,
  readOnly: false
};

Timezone.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  value: PropTypes.string,
  time: PropTypes.string
};
