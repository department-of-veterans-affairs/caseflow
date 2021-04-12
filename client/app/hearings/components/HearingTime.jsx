import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import { zoneName } from '../utils';
import moment from 'moment-timezone';

const firstParagraphStyle = css({ marginTop: 0 });

export const HearingTime = ({
  hearing,
  showIssueCount,
  showRegionalOfficeName,
  showRequestType,
  labelClasses,
  breakCharacter,
  paragraphClasses,
  primaryLabel,
}) => {
  // Default to using EST for all times before conversion
  moment.tz.setDefault(hearing.regionalOfficeTimezone || 'America/New_York');

  // Determine whether to display the appellant timezone
  const repTimezone =
    hearing.virtualHearing?.appellantTz === hearing.regionalOfficeTimezone &&
    hearing.regionalOfficeTimezone === 'America/New_York' ?
      '' :
      hearing.virtualHearing?.appellantTz || hearing.regionalOfficeTimezone;

  // Determine what timezone to use; always use RO timezone for video/formerly-video hearings
  const timezone =
    hearing.isVirtual && hearing.readableRequestType !== 'Video' ?
      repTimezone :
      hearing.regionalOfficeTimezone || 'America/New_York';

  // Calculate the local time based on either Regional Office or Representative for Virtual hearings
  const localTime = zoneName(hearing.scheduledTimeString, timezone, 'z');

  // Calculate the central office time
  const coTime = zoneName(hearing.scheduledTimeString, 'America/New_York', 'z');

  // Determine whether to show the Regional Office time as the primary label
  const primaryTime = primaryLabel === 'RO' ? localTime : coTime;
  const secondaryTime = primaryLabel === 'RO' ? coTime : localTime;

  return (
    <div>
      {showRequestType && (
        <p {...firstParagraphStyle}>
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

HearingTime.defaultProps = {
  primaryLabel: 'C',
  showIssueCount: false,
  showRegionalOfficeName: false,
  showRequestType: false,
  breakCharacter: ' /',
};

HearingTime.propTypes = {
  primaryLabel: PropTypes.string,
  breakCharacter: PropTypes.string,
  labelClasses: PropTypes.string,
  paragraphClasses: PropTypes.string,
  hearing: PropTypes.shape({
    virtualHearing: PropTypes.object,
    currentIssueCount: PropTypes.number,
    scheduledTimeString: PropTypes.string.isRequired,
    readableRequestType: PropTypes.string.isRequired,
    regionalOfficeName: PropTypes.string,
    regionalOfficeTimezone: PropTypes.string,
    centralOfficeTimeString: PropTypes.string.isRequired,
    isVirtual: PropTypes.bool,
  }),
  // Show the number of issues related to the given hearing.
  showIssueCount: PropTypes.bool,
  // Show the regional office name associated with the timezone.
  showRegionalOfficeName: PropTypes.bool,
  // Show the hearing's request type.
  showRequestType: PropTypes.bool,
};
