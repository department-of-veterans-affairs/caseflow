import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

import HEARING_TIME_OPTIONS from '../../../constants/HEARING_TIME_OPTIONS';
import SearchableDropdown from '../../components/SearchableDropdown';
import { hearingTimeOptsWithZone } from '../utils';

export const getAssignHearingTime = (time, day) => {
  return {
    // eslint-disable-next-line id-length
    h: time.split(':')[0],
    // eslint-disable-next-line id-length
    m: time.split(':')[1],
    offset: moment.
      tz(
        day.hearingDate || day.scheduledFor,
        day.timezone || 'America/New_York'
      ).
      format('Z'),
  };
};

export const TimePicker = ({
  localZone,
  componentIndex,
  onChange,
  readOnly,
  regionalOffice,
  value,
  enableZone,
  hideLabel,
}) => {

  return (
    <SearchableDropdown
      readOnly={readOnly}
      name={`optionalHearingTime${componentIndex}`}
      label="Hearing Time"
      strongLabel
      placeholder="Select a time"
      options={
        enableZone ?
          hearingTimeOptsWithZone(HEARING_TIME_OPTIONS, localZone || enableZone) :
          HEARING_TIME_OPTIONS
      }
      value={value}
      onChange={(option) => onChange(option ? option.value : null)}
      hideLabel={hideLabel}
    />
  );
};

TimePicker.defaultProps = {
  componentIndex: 0,
  enableZone: false,
};

TimePicker.propTypes = {
  enableZone: PropTypes.bool,
  componentIndex: PropTypes.number,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  regionalOffice: PropTypes.string,
  value: PropTypes.string,
  label: PropTypes.string,
  localZone: PropTypes.string,
  hideLabel: PropTypes.bool,
};
