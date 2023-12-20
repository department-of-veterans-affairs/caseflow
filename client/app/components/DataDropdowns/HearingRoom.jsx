import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { HEARING_ROOM_OPTIONS } from './constants';
import SearchableDropdown from '../SearchableDropdown';
import COPY from '../../../COPY';

export const HearingRoomDropdown = (
  { name, label, value, onChange, readOnly, errorMessage, placeholder }
) => {
  const selectedOption = _.find(HEARING_ROOM_OPTIONS, (opt) => opt.value === value) ||
    {
      value: null,
      label: null
    };

  return (
    <SearchableDropdown
      name={name}
      label={label}
      strongLabel
      readOnly={readOnly}
      value={selectedOption}
      onChange={(option) => onChange((option || {}).value, (option || {}).label)}
      options={HEARING_ROOM_OPTIONS}
      errorMessage={errorMessage}
      placeholder={placeholder}
    />
  );
};

HearingRoomDropdown.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.string,
  onChange: PropTypes.func.isRequired,
  readOnly: PropTypes.bool,
  placeholder: PropTypes.string,
  errorMessage: PropTypes.string
};

HearingRoomDropdown.defaultProps = {
  name: 'room',
  label: COPY.DROPDOWN_LABEL_HEARING_ROOM
};
