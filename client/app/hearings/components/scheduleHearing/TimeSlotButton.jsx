import React from 'react';
import PropTypes from 'prop-types';

import DocketTypeBadge from '../../../components/DocketTypeBadge';
import Button from 'app/components/Button';

import { formatTimeSlotLabel } from '../../utils';

export const TimeSlotButton = ({
  hearingTime,
  roTimezone,
  selected,
  issueCount,
  poaName,
  docketName,
  docketNumber,
  full,
  onClick
}) => {
  const selectedClass = selected ? 'time-slot-button-selected' : '';
  const fullClass = full ? 'time-slot-button-full' : '';

  const issueLabel = issueCount === 1 ? `${issueCount} issue` : `${issueCount} issues`;

  return (
    <Button
      onClick={onClick}
      disabled={full}
      classNames={[
        'usa-button-secondary',
        'time-slot-button',
        selectedClass,
        fullClass,
      ]}
    >
      <div>
        <div style={{ flex: 1 }}>
          {formatTimeSlotLabel(hearingTime, roTimezone)}
          {full && issueCount !== null && poaName && (
            <div className="time-slot-details">
              {issueLabel} <span>&#183;</span>{' '}
              <DocketTypeBadge name={docketName} number={docketNumber} />{' '}
              <span>&#183;</span> {poaName}
            </div>
          )}
        </div>
        <div>
          {!selected && !full && (
            <i className="fa fa-angle-right time-slot-arrow" />
          )}
        </div>
      </div>
    </Button>
  );
};

TimeSlotButton.defaultProps = {
  full: false,
  selected: false,
};

TimeSlotButton.propTypes = {
  onClick: PropTypes.func,
  issueCount: PropTypes.number,
  docketName: PropTypes.string,
  full: PropTypes.bool,
  docketNumber: PropTypes.string,
  poaName: PropTypes.string,
  hearingTime: PropTypes.string,
  roTimezone: PropTypes.string,
  selected: PropTypes.bool,
};
