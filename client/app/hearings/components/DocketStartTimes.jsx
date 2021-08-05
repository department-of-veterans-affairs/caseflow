import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';
import { shortZoneName } from '../utils';

import { RadioField } from '../../components/RadioField';

export const DocketStartTimes = ({
  hearingStartTime,
  setSlotCount,
  setHearingStartTime,
  roTimezone = 'America/New_York'
}) => {
  const fullDayAmPm = 'default';
  const eightThirty = '8:30';
  const twelveThirty = '12:30';
  const halfDayAm = moment.tz(eightThirty, 'HH:mm', roTimezone).tz('America/New_York').
    format('HH:mm');
  const halfDayPm = moment.tz(twelveThirty, 'HH:mm', roTimezone).tz('America/New_York').
    format('HH:mm');
  const fullDaySlots = 10;
  const halfDaySlots = fullDaySlots / 2;
  const timezone = roTimezone ?? 'America/New_York';

  const formatTimeStrings = () => {
    const amTimeInEastern = moment.tz(eightThirty, 'HH:mm', roTimezone).tz('America/New_York').
      format('h:mm A');
    const pmTimeInEastern = moment.tz(twelveThirty, 'HH:mm', roTimezone).tz('America/New_York').
      format('h:mm A');

    return { amTimeInEastern, pmTimeInEastern };
  };

  const formatTimeLabels = (amTimeInEastern, pmTimeInEastern) => {
    const zoneName = shortZoneName(timezone);

    const fullDayAmPmLabel =
      `Full-Day AM & PM (${fullDaySlots} slots at ${eightThirty} AM & ${twelveThirty} PM ${zoneName})`;
    let halfDayAmLabel =
      `Half-Day AM (${halfDaySlots} slots at ${eightThirty} AM ${zoneName} / ${amTimeInEastern} Eastern)`;
    let halfDayPmLabel =
      `Half-Day PM (${halfDaySlots} slots at ${twelveThirty} PM ${zoneName} / ${pmTimeInEastern} Eastern)`;

    if (zoneName === 'Eastern') {
      halfDayAmLabel =
        `Half-Day AM (${halfDaySlots} slots at ${amTimeInEastern} ${zoneName})`;
      halfDayPmLabel =
        `Half-Day PM (${halfDaySlots} slots at ${pmTimeInEastern} ${zoneName})`;
    }

    return { fullDayAmPmLabel, halfDayAmLabel, halfDayPmLabel };
  };

  const options = () => {
    const { amTimeInEastern, pmTimeInEastern } = formatTimeStrings();
    const { fullDayAmPmLabel, halfDayAmLabel, halfDayPmLabel } = formatTimeLabels(
      amTimeInEastern, pmTimeInEastern
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
