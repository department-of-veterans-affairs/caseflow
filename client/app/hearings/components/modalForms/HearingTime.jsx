import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import moment from 'moment-timezone';

import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import HEARING_TIME_RADIO_OPTIONS from '../../../../constants/HEARING_TIME_RADIO_OPTIONS';
import RadioField from '../../../components/RadioField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import { hearingTimeOptsWithZone } from '../../utils';
import { verticalAlign } from '../details/style';

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

const formStyling = css({
  '& .cf-form-radio-option:not(:last-child)': {
    display: 'inline-block',
    marginRight: '25px',
  },
  marginBottom: 0,
});

const getTimeOptions = (regionalOffice, readOnly) =>
  _.map(
    regionalOffice === 'C' ?
      HEARING_TIME_RADIO_OPTIONS.central :
      HEARING_TIME_RADIO_OPTIONS.default,
    (obj) => _.extend(obj, { disabled: readOnly })
  );

export const HearingTime = ({
  localZone,
  componentIndex,
  errorMessage,
  onChange,
  readOnly,
  regionalOffice,
  value,
  enableZone,
  disableRadioOptions,
  label,
  vertical,
  hideLabel,
}) => {
  const timeOptions = getTimeOptions(regionalOffice, readOnly);
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

  // Determine the radio button alignment
  const align = vertical ? verticalAlign : {};

  return (
    <React.Fragment>
      {!disableRadioOptions && (
        <span {...formStyling} {...align}>
          <RadioField
            errorMessage={errorMessage}
            name={`hearingTime${componentIndex}`}
            label={label || 'Time'}
            strongLabel
            options={enableZone ? hearingTimeOptsWithZone(timeOptions, localZone || enableZone) : timeOptions}
            onChange={onRadioChange}
            value={isOther ? 'other' : value}
          />
        </span>
      )}
      {(isOther || disableRadioOptions) && (
        <SearchableDropdown
          readOnly={readOnly}
          name={`optionalHearingTime${componentIndex}`}
          label={label}
          strongLabel
          placeholder="Select a time"
          options={
            enableZone ?
              hearingTimeOptsWithZone(HEARING_TIME_OPTIONS, localZone || enableZone) :
              HEARING_TIME_OPTIONS
          }
          value={value}
          onChange={(option) => onChange(option ? option.value : null)}
          hideLabel={!disableRadioOptions || hideLabel}
        />
      )}
    </React.Fragment>
  );
};

HearingTime.defaultProps = {
  label: 'Hearing Time',
  componentIndex: 0,
  enableZone: false,
};

HearingTime.propTypes = {
  disableRadioOptions: PropTypes.bool,
  enableZone: PropTypes.bool,
  componentIndex: PropTypes.number,
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  readOnly: PropTypes.bool,
  vertical: PropTypes.bool,
  regionalOffice: PropTypes.string,
  value: PropTypes.string,
  label: PropTypes.string,
  localZone: PropTypes.string,
  hideLabel: PropTypes.bool,
};
