import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';
import { shortZoneName } from '../utils';

import { RadioField } from '../../components/RadioField';

export const DocketStartTimes = (props) => {
  const {
    hearingStartTime,
    setSlotCount,
    setHearingStartTime,
    roTimezone
  } = props;

  const fullDayAmPm = null
  const halfDayAm = '8:30'
  const halfDayPm = '12:30'

  const options = () => {
    const amTimeInEastern =
      moment(moment.tz(halfDayAm, 'h:mm A', roTimezone)).tz('America/New_York').format('h:mm A');
    const pmTimeInEastern =
      moment(moment.tz(halfDayPm, 'h:mm A', roTimezone)).tz('America/New_York').format('h:mm A');

    const zoneName = shortZoneName(roTimezone)
    const fullDayAmPmLabel = `Full-Day AM & PM (10 slots at ${halfDayAm} AM & ${halfDayPm} PM ${zoneName})`
    let halfDayAmLabel = `Half-Day AM (5 slots at ${halfDayAm} AM ${name} / ${amTimeInEastern} Eastern)`
    let halfDayPmLabel = `Half-Day PM (5 slots at ${halfDayPm} PM ${name} / ${pmTimeInEastern} Eastern)`

    if (zoneName === 'Eastern') {
      halfDayAmLabel = `Half-Day AM (5 slots at ${amTimeInEastern} ${zoneName})`
      halfDayPmLabel = `Half-Day PM (5 slots at ${pmTimeInEastern} ${zoneName})`
    }

    return [
      { displayText: fullDayAmPmLabel,
        value: fullDayAmPm },
      { displayText: halfDayAmLabel,
        value: halfDayAm },
      { displayText: halfDayPmLabel,
        value: halfDayPm }
    ]
  }

  const docketTypeSlotCount = {
    [fullDayAmPm]: 10,
    [halfDayAm]: 5,
    [halfDayPm]: 5
  }

  const handleOnChange = (value) => {
    value === fullDayAmPm ? setHearingStartTime(null) : setHearingStartTime(value)

    setSlotCount(docketTypeSlotCount[value] ?? null)
  }

  return (
    <RadioField
      name={'docketAvailableTimes'}
      label={'Available Times'}
      strongLabel
      options={options()}
      onChange={(value) => handleOnChange(value)}
      value={hearingStartTime}
    />
  )
};

DocketStartTimes.propTypes = {
  roTimezone: PropTypes.string,
  hearingStartTime: PropTypes.string,
  setSlotCount: PropTypes.func,
  setHearingStartTime: PropTypes.func
};
