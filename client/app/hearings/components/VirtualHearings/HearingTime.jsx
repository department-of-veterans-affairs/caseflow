import React from 'react';
import PropTypes from 'prop-types';

import { hearingTimeOptsWithZone } from '../../utils';
import SearchableDropdown from '../../../components/SearchableDropdown';

export const HearingTime = ({ readOnly, value, errorMessage, onChange }) => {
  return (
    <SearchableDropdown
      readOnly={readOnly !== false}
      name="Hearing Time"
      placeholder="Select a time"
      options={hearingTimeOptsWithZone()}
      value={value}
      onChange={(option) => onChange(option ? option.value : null)}
      errorMessage={errorMessage}
      strongLabel
    />
  );
};

HearingTime.defaultProps = {
  value: null,
  readOnly: true
};

HearingTime.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  value: PropTypes.string.isRequired
};
