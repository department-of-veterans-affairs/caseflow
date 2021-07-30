import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';
import { shortZoneName } from '../utils';

import { RadioField } from '../../components/RadioField';

export const DocketStartTimes = ({
  hearingStartTime,
  setSlotCount,
  setHearingStartTime,
  roTimezone
}) => {
  const fullDayAmPm = 'default';
  const halfDayAm = '8:30';
  const halfDayPm = '12:30';

  const options = () => {
    const timezone = roTimezone ?? 'America/New_York';
    const amTimeInEastern =
      moment(moment.tz(halfDayAm, 'h:mm A', timezone)).tz('America/New_York').
        format('h:mm A');
    const pmTimeInEastern =
      moment(moment.tz(halfDayPm, 'h:mm A', timezone)).tz('America/New_York').
        format('h:mm A');

    const zoneName = shortZoneName(timezone);
    const fullDayAmPmLabel = `Full-Day AM & PM (10 slots at ${halfDayAm} AM & ${halfDayPm} PM ${zoneName})`;
    let halfDayAmLabel = `Half-Day AM (5 slots at ${halfDayAm} AM ${zoneName} / ${amTimeInEastern} Eastern)`;
    let halfDayPmLabel = `Half-Day PM (5 slots at ${halfDayPm} PM ${zoneName} / ${pmTimeInEastern} Eastern)`;

    if (zoneName === 'Eastern') {
      halfDayAmLabel = `Half-Day AM (5 slots at ${amTimeInEastern} ${zoneName})`;
      halfDayPmLabel = `Half-Day PM (5 slots at ${pmTimeInEastern} ${zoneName})`;
    }

    return [
      { displayText: fullDayAmPmLabel,
        value: fullDayAmPm },
      { displayText: halfDayAmLabel,
        value: halfDayAm },
      { displayText: halfDayPmLabel,
        value: halfDayPm }
    ];
  };

  const startTimesSlotCount = {
    [fullDayAmPm]: 10,
    [halfDayAm]: 5,
    [halfDayPm]: 5
  };

  const onChange = (value) => {
    if (value === fullDayAmPm) {
      setHearingStartTime(null);
    } else {
      setHearingStartTime(value);
    }

    setSlotCount(startTimesSlotCount[value]);
  };

  return (
    <RadioField
      name="docketStartTimes"
      label="Available Times"
      strongLabel
      options={options()}
      onChange={(value) => onChange(value)}
      value={hearingStartTime ?? fullDayAmPm }
    />
  );
};

DocketStartTimes.propTypes = {
  roTimezone: PropTypes.string,
  hearingStartTime: PropTypes.string,
  setSlotCount: PropTypes.func,
  setHearingStartTime: PropTypes.func
};
