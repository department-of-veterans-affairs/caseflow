// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { sortBy } from 'lodash';

// Component Dependencies
import { TimeSlotCard } from './TimeSlotCard';

/**
 * Assign Hearings List Component
 * @param {Object} props -- Contains the hearings list, selected hearing day and regional office
 */
export const AssignHearingsList = ({ hearings, hearingDay, regionalOffice }) => {
  return hearings.length ? sortBy(hearings, 'scheduledTimeString').map((hearing) => (
    <TimeSlotCard
      key={hearing.appealExternalId}
      hearing={hearing}
      hearingDay={hearingDay}
      regionalOffice={regionalOffice}
    />
  )) : (
    <div className="time-slot-card-label no-hearings-label">No Upcoming hearings to display</div>
  );
};

AssignHearingsList.propTypes = {
  hearings: PropTypes.array,
  hearingDay: PropTypes.object,
  regionalOffice: PropTypes.string,
};
