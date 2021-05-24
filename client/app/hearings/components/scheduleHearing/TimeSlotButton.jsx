import React from 'react';
import PropTypes from 'prop-types';

import Button from 'app/components/Button';
import { TimeSlotDetail } from './TimeSlotDetail';

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
          <TimeSlotDetail
            constrainWidth
            showDetails={Boolean(full && issueCount !== null && poaName)}
            label={formatTimeSlotLabel(hearingTime, roTimezone)}
            issueCount={issueCount}
            poaName={poaName}
            docketName={docketName}
            docketNumber={docketNumber}
          />
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
  preview: PropTypes.bool,
};
