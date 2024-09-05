import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment-timezone';
import { shortZoneName } from '../utils';

import { RadioField } from '../../components/RadioField';

export const DocketStartTimes = ({
  hearingStartTime,
  setHearingStartTime,
  setSlotCount,
  roTimezone = 'America/New_York',
  amStartTime = '8:30',
  pmStartTime = '12:30',
  slots = 10
}) => {
  const roTimezoneToEastern = (stringInEastern, timezone, withAmPm = false) =>
    moment.tz(stringInEastern, 'HH:mm', timezone).tz('America/New_York')?.
      format(withAmPm ? 'h:mm A' : 'HH:mm');

  const formatWithAMPM = (timeString) => moment(timeString, 'HH:mm')?.format('h:mm A');

  const formatHalfDayLabel = (halfDaySlotCount, timeInEastern, timeInRoTimezone, timezone, amOrPm) => {
    const zoneName = shortZoneName(timezone);

    const nonEasternTimezoneInfo = zoneName === 'Eastern' ? '' : ` / ${timeInEastern} Eastern`;

    return `Half-Day ${amOrPm} (${halfDaySlotCount} slots at ${timeInRoTimezone} ${zoneName}${nonEasternTimezoneInfo})`;
  };

  const formatTimeLabels = (amStartTimeString, pmStartTimeString, fullDaySlots, timezone) => {
    const zoneName = shortZoneName(timezone);
    const amTimeInEastern = roTimezoneToEastern(amStartTimeString, timezone, true);
    const pmTimeInEastern = roTimezoneToEastern(pmStartTimeString, timezone, true);
    const amTimeWithAM = formatWithAMPM(amStartTimeString, timezone);
    const pmTimeWithPM = formatWithAMPM(pmStartTimeString, timezone);

    const fullDayAmPmLabel =
      `Full-Day AM & PM (${fullDaySlots} slots at ${amTimeWithAM} & ${pmTimeWithPM} ${zoneName})`;
    let halfDayAmLabel = formatHalfDayLabel(fullDaySlots / 2, amTimeInEastern, amTimeWithAM, timezone, 'AM');
    let halfDayPmLabel = formatHalfDayLabel(fullDaySlots / 2, pmTimeInEastern, pmTimeWithPM, timezone, 'PM');

    return { fullDayAmPmLabel, halfDayAmLabel, halfDayPmLabel };
  };

  const getOptions = (amStartTimeString, pmStartTimeString, timezone, fullDaySlots) => {
    const { fullDayAmPmLabel, halfDayAmLabel, halfDayPmLabel } = formatTimeLabels(
      amStartTimeString, pmStartTimeString, fullDaySlots, timezone
    );

    return [
      { displayText: fullDayAmPmLabel,
        value: 'default',
        slotCount: fullDaySlots
      },
      { displayText: halfDayAmLabel,
        value: roTimezoneToEastern(amStartTimeString, roTimezone),
        slotCount: fullDaySlots / 2
      },
      { displayText: halfDayPmLabel,
        value: roTimezoneToEastern(pmStartTimeString, roTimezone),
        slotCount: fullDaySlots / 2
      }
    ];
  };

  const onChange = (value, newSlotCount) => {
    if (value === 'default') {
      setHearingStartTime(null);
    } else {
      setHearingStartTime(value);
    }
    setSlotCount(newSlotCount);
  };
  const options = getOptions(amStartTime, pmStartTime, roTimezone, slots);

  return (
    <RadioField
      name="docketStartTimes"
      label="Available Times"
      strongLabel
      options={options}
      onChange={(value) => {
        const newSlotCount = options.find((option) => option.value === value).slotCount;

        onChange(value, newSlotCount);
      }}
      value={hearingStartTime ?? 'default'}
    />
  );
};

DocketStartTimes.propTypes = {
  roTimezone: PropTypes.string,
  hearingStartTime: PropTypes.string,
  setHearingStartTime: PropTypes.func,
  setSlotCount: PropTypes.func,
  amStartTime: PropTypes.string,
  pmStartTime: PropTypes.string,
  slots: PropTypes.number
};
