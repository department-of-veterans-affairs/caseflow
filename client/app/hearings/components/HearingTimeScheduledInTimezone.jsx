import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment-timezone';

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
  const timeInScheduledTimezone = moment(hearing.scheduledFor).tz(hearing.scheduledInTimezone).
    format('h:mm A z');

  // Calculate the central office time
  const coTime = moment(hearing.scheduledFor).tz('America/New_York').
    format('h:mm A z');

  const primaryTime = primaryLabel === 'RO' ? timeInScheduledTimezone : coTime;
  const secondaryTime = primaryLabel === 'RO' ? coTime : timeInScheduledTimezone;

  return (
    <div>
      {showRequestType && (
        <p className="hearing-time-scheduled-in-timezone">
          <b>{hearing.isVirtual ? 'Virtual' : hearing.readableRequestType}</b>
        </p>
      )}
      <p className={paragraphClasses}>
        <span className={labelClasses}>{primaryTime}</span>
        {primaryTime !== secondaryTime && (
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
