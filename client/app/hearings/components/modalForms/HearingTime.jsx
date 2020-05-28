import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import HEARING_TIME_RADIO_OPTIONS from '../../../../constants/HEARING_TIME_RADIO_OPTIONS';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';

export const getAssignHearingTime = (time, day) => {
  return {
    // eslint-disable-next-line id-length
    h: time.split(':')[0],
    // eslint-disable-next-line id-length
    m: time.split(':')[1],
    offset: moment.tz(day.hearingDate || day.scheduledFor, day.timezone || 'America/New_York').format('Z')
  };
};

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px'
  },
  marginBottom: 0
});

let index = 0;

const getTimeOptions = (regionalOffice, readOnly) => (
  _.map(
    regionalOffice === 'C' ? HEARING_TIME_RADIO_OPTIONS.central : HEARING_TIME_RADIO_OPTIONS.default,
    (obj) => _.extend(obj, { disabled: readOnly })
  )
);

export const HearingTime = ({ errorMessage, onChange, readOnly, regionalOffice, value }) => {
  const timeOptions = getTimeOptions(regionalOffice, readOnly);
  const componentIndex = (index += 1);
  const isOther = _.isUndefined(
    _.find(timeOptions, (opt) => opt.value === value)
  );
  const onRadioChange = (newValue) => {
    if (newValue === 'other') {
      onChange(null);
    } else {
      onChange(newValue);
    }
  };

  return (
    <React.Fragment>
      <span {...formStyling}>
        <RadioField
          errorMessage={errorMessage}
          name={`hearingTime${componentIndex}`}
          label="Time"
          strongLabel
          options={timeOptions}
          onChange={onRadioChange}
          value={isOther ? 'other' : value}
        />
      </span>
      {isOther && (
        <SearchableDropdown
          readOnly={readOnly}
          name={`optionalHearingTime${componentIndex}`}
          placeholder="Select a time"
          options={HEARING_TIME_OPTIONS}
          value={value}
          onChange={(option) => onChange(option ? option.value : null)}
          hideLabel
        />
      )}
    </React.Fragment>
  );
};

HearingTime.propTypes = {
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  regionalOffice: PropTypes.string,
  value: PropTypes.string
};
