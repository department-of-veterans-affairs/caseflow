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
  const halfDayAm = '08:30';
  const halfDayPm = '12:30';
  const fullDaySlots = 10;
  const halfDaySlots = fullDaySlots / 2;
  const timezone = roTimezone ?? 'America/New_York';

  const formatTimeStrings = () => {
    // remove leading zero from 08:30 for display
    const amTime = halfDayAm.slice(1);

    const amTimeInEastern =
      moment(moment.tz(halfDayAm, 'h:mm A', timezone)).tz('America/New_York').
        format('h:mm A');
    const pmTimeInEastern =
      moment(moment.tz(halfDayPm, 'h:mm A', timezone)).tz('America/New_York').
        format('h:mm A');

    return { amTime, amTimeInEastern, pmTimeInEastern };
  };

  const formatTimeLabels = (amTime, amTimeInEastern, pmTimeInEastern) => {
    const zoneName = shortZoneName(timezone);

    const fullDayAmPmLabel =
      `Full-Day AM & PM (${fullDaySlots} slots at ${amTime} AM & ${halfDayPm} PM ${zoneName})`;
    let halfDayAmLabel =
      `Half-Day AM (${halfDaySlots} slots at ${amTime} AM ${zoneName} / ${amTimeInEastern} Eastern)`;
    let halfDayPmLabel =
      `Half-Day PM (${halfDaySlots} slots at ${halfDayPm} PM ${zoneName} / ${pmTimeInEastern} Eastern)`;

    if (zoneName === 'Eastern') {
      halfDayAmLabel =
        `Half-Day AM (${halfDaySlots} slots at ${amTimeInEastern} ${zoneName})`;
      halfDayPmLabel =
        `Half-Day PM (${halfDaySlots} slots at ${pmTimeInEastern} ${zoneName})`;
    }

    return { fullDayAmPmLabel, halfDayAmLabel, halfDayPmLabel };
  };

  const options = () => {
    const { amTime, amTimeInEastern, pmTimeInEastern } = formatTimeStrings();
    const { fullDayAmPmLabel, halfDayAmLabel, halfDayPmLabel } = formatTimeLabels(
      amTime, amTimeInEastern, pmTimeInEastern
    );

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
    [fullDayAmPm]: fullDaySlots,
    [halfDayAm]: halfDaySlots,
    [halfDayPm]: halfDaySlots
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
      value={hearingStartTime ?? fullDayAmPm}
    />
  );
};

DocketStartTimes.propTypes = {
  roTimezone: PropTypes.string,
  hearingStartTime: PropTypes.string,
  setSlotCount: PropTypes.func,
  setHearingStartTime: PropTypes.func
};
