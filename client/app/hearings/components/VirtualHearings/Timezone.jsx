import React from 'react';
import PropTypes from 'prop-types';

import SearchableDropdown from '../../../components/SearchableDropdown';
import { timezones } from '../../utils';
import { timezoneStyles } from '../details/style';

export const Timezone = ({
  name,
  label,
  readOnly,
  value,
  errorMessage,
  onChange,
  time,
  roTimezone,
  required
}) => {
  const { options, commonsCount } = timezones(time, roTimezone);

  return (
    <SearchableDropdown
      required={!readOnly && required}
      styling={timezoneStyles(commonsCount)}
      name={name}
      label={label}
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
  name: 'Timezone',
  value: null,
  readOnly: false
};

Timezone.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  required: PropTypes.bool,
  value: PropTypes.string,
  name: PropTypes.string,
  label: PropTypes.string,
  time: PropTypes.string.isRequired,
  roTimezone: PropTypes.string.isRequired
};
