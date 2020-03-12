import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';

import { getDisplayTime } from '../../util/DateUtil';

const firstParagraphStyle = css({ marginTop: 0 });

export const HearingTime = (
  { hearing, showIssueCount, showRegionalOfficeName, showRequestType }
) => {
  const localTime = getDisplayTime(
    hearing.scheduledTimeString,
    hearing.regionalOfficeTimezone || 'America/New_York'
  );
  const coTime = getDisplayTime(hearing.centralOfficeTimeString, 'America/New_York');
  const isCentralOffice = hearing.readableRequestType === 'Central';

  return (
    <div>
      {showRequestType &&
        <p {...firstParagraphStyle}>
          <b>{hearing.isVirtual ? 'Virtual' : hearing.readableRequestType}</b>
        </p>
      }
      <p>
        {coTime}
        {!isCentralOffice &&
          <> /<br />{localTime}</>
        }
        {showRegionalOfficeName &&
          <><br />{hearing.regionalOfficeName}</>
        }
      </p>
      {isCentralOffice && showIssueCount &&
        <p>{hearing.currentIssueCount} issues</p>
      }
    </div>
  );
};

HearingTime.defaultProps = {
  showIssueCount: false,
  showRegionalOfficeName: false,
  showRequestType: false
};

HearingTime.propTypes = {
  hearing: PropTypes.shape({
    currentIssueCount: PropTypes.number,
    scheduledTimeString: PropTypes.string.isRequired,
    readableRequestType: PropTypes.string.isRequired,
    regionalOfficeName: PropTypes.string,
    regionalOfficeTimezone: PropTypes.string,
    centralOfficeTimeString: PropTypes.string.isRequired,
    isVirtual: PropTypes.bool
  }),
  // Show the number of issues related to the given hearing.
  showIssueCount: PropTypes.bool,
  // Show the regional office name associated with the timezone.
  showRegionalOfficeName: PropTypes.bool,
  // Show the hearing's request type.
  showRequestType: PropTypes.bool
};
