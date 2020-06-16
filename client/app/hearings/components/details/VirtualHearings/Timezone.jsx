import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

import SearchableDropdown from '../../../../components/SearchableDropdown';
import { timezones } from '../../../utils';

export const Timezone = ({ readOnly, value, errorMessage, onChange }) => {
  const { options, commons } = timezones();

  return (
    <SearchableDropdown
      name="Timezone"
      readOnly={readOnly}
      placeholder="Select a time"
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
  value: PropTypes.string
};
