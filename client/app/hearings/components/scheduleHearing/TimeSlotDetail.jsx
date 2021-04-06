import React from 'react';
import PropTypes from 'prop-types';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import DocketTypeBadge from '../../../components/DocketTypeBadge';

export const TimeSlotDetail = ({
  issueCount,
  poaName,
  docketName,
  docketNumber,
  label,
  showDetails,
  showType,
  caseType,
  appealId,
  requestType,
}) => {
  const issueLabel =
    issueCount === 1 ? `${issueCount} issue` : `${issueCount} issues`;

  return (
    <React.Fragment>
      {label}
      {showDetails && (
        <div className="time-slot-details">
          {issueLabel} <span>&#183;</span>{' '}
          <DocketTypeBadge name={docketName} number={docketNumber} />{' '}
          <span>&#183;</span> {poaName}
        </div>
      )}
      {showType && (
        <div className="time-slot-details">
          {caseType} <span>&#183;</span> {requestType}
          <span>&#183;</span> <Link to={`/queue/appeals/${appealId}`}>View Case Details</Link>
        </div>
      )}
    </React.Fragment>
  );
};

TimeSlotDetail.propTypes = {
  issueCount: PropTypes.number,
  docketName: PropTypes.string,
  caseType: PropTypes.string,
  appealId: PropTypes.string,
  requestType: PropTypes.string,
  label: PropTypes.string,
  docketNumber: PropTypes.string,
  showDetails: PropTypes.bool,
  showType: PropTypes.bool,
  poaName: PropTypes.string,
};
