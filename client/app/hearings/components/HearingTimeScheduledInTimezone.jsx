import PropTypes from 'prop-types';
import React from 'react';

import { zoneName } from '../utils';
import momentTimezone from 'moment-timezone';
import moment from 'moment';

export const HearingTimeScheduledInTimezone = ({
  hearing,
  showIssueCount,
  showRequestType,
  labelClasses,
  breakCharacter,
  paragraphClasses,
  primaryLabel,
  showRegionalOfficeName,
}) => {
  const timeInScheduledTimezone = zoneName(hearing.scheduledTimeString, hearing.scheduledInTimezone, 'z');

  // Calculate the central office time
  // scheduledTime received from BE is 1hr ahead of the values selected in radio options(which is incorrect)
  // To fix it, display the time in EST always
  const estTime = moment(hearing.scheduledFor).utcOffset('-05:00').
    format('h:mm A');
  const tz = momentTimezone().tz('America/New_York').
    format('z');

  const coTime = `${estTime} ${tz}`;
  const primaryTime = primaryLabel === 'RO' ? timeInScheduledTimezone : coTime;
  const secondaryTime = primaryLabel === 'RO' ? coTime : timeInScheduledTimezone;

  const isTimeZoneDifferent = hearing.scheduledInTimezone !== 'America/New_York';

  return (
    <div>
      {showRequestType && (
        <p className="hearing-time-scheduled-in-timezone">
          <b>{hearing.isVirtual ? 'Virtual' : hearing.readableRequestType}</b>
        </p>
      )}
      <p className={paragraphClasses}>
        <span className={labelClasses}>{primaryTime}</span>
        {isTimeZoneDifferent && (
          <>
            {breakCharacter}
            <br />
            {secondaryTime}
          </>
        )}
        {showRegionalOfficeName && (
          <>
            <br />
            {hearing.regionalOfficeName}
          </>
        )}
      </p>
      {showIssueCount && <p>{hearing.currentIssueCount} issues</p>}
    </div>
  );
};

HearingTimeScheduledInTimezone.defaultProps = {
  showIssueCount: false,
  showRegionalOfficeName: false,
  showRequestType: false,
  breakCharacter: ' /',
  labelClasses: '',
  paragraphClasses: '',
  primaryLabel: '',
};

HearingTimeScheduledInTimezone.propTypes = {
  primaryLabel: PropTypes.string,
  breakCharacter: PropTypes.string,
  labelClasses: PropTypes.string,
  paragraphClasses: PropTypes.string,
  showRegionalOfficeName: PropTypes.bool,
  hearing: PropTypes.shape({
    currentIssueCount: PropTypes.number,
    scheduledTimeString: PropTypes.string.isRequired,
    readableRequestType: PropTypes.string.isRequired,
    isVirtual: PropTypes.bool,
    scheduledInTimezone: PropTypes.string.isRequired,
    regionalOfficeName: PropTypes.string,
    scheduledFor: PropTypes.string,
  }),
  // Show the number of issues related to the given hearing.
  showIssueCount: PropTypes.bool,
  // Show the hearing's request type.
  showRequestType: PropTypes.bool,
};
