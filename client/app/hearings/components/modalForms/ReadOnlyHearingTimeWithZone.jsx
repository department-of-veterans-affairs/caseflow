import React, { useEffect } from 'react';
import moment from 'moment-timezone';
import PropTypes from 'prop-types';

import { ReadOnly } from '../details/ReadOnly';
import { shortZoneName } from '../../utils';

export const ReadOnlyHearingTimeWithZone = ({
  hearingStartTime,
  timezone,
  onRender
}) => {
  useEffect(() => {
    if (hearingStartTime) {
      onRender(moment(hearingStartTime).tz(timezone, true).
        format('hh:mm'));
    }
  }, []);

  if (!hearingStartTime) {
    return null;
  }

  const zoneName = shortZoneName(timezone);
  const dateTime = moment(hearingStartTime).tz(timezone, true);
  let displayTime = `${dateTime.format('h:mm A')} ${zoneName}`;

  if (zoneName !== 'Eastern') {
    displayTime =
      `${displayTime} / ${moment(dateTime).tz('America/New_York').
        format('h:mm A')} Eastern`;
  }

  return (
    <ReadOnly
      label="Hearing Time"
      text={displayTime}
    />
  );
};

ReadOnlyHearingTimeWithZone.propTypes = {
  hearingStartTime: PropTypes.string,
  timezone: PropTypes.string,
  onRender: PropTypes.func
};
