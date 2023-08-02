import PropTypes from 'prop-types';
import React from 'react';
import { isEmpty } from 'lodash';

import { NoUpcomingHearingDayMessage } from './Messages';
import AssignHearingsTabs from './AssignHearingsTabs';
import { HearingDaysNav } from './HearingDaysNav';

/**
 * Assign Hearings Component
 * @param {Object} props --  Contains the list of hearing days and the selected hearing day
 */
export const AssignHearings = ({
  upcomingHearingDays,
  selectedHearingDay,
  selectedRegionalOffice,
  onSelectedHearingDayChange
}) => isEmpty(upcomingHearingDays) ? (
  <NoUpcomingHearingDayMessage />
) : (
  <React.Fragment>
    <HearingDaysNav
      upcomingHearingDays={upcomingHearingDays}
      selectedHearingDay={selectedHearingDay}
      onSelectedHearingDayChange={onSelectedHearingDayChange}
    />
    <AssignHearingsTabs
      selectedRegionalOffice={selectedRegionalOffice}
      selectedHearingDay={selectedHearingDay}
      room={selectedHearingDay?.room}
    />
  </React.Fragment>
);

AssignHearings.propTypes = {
  // Selected Regional Office Key
  selectedRegionalOffice: PropTypes.string,

  upcomingHearingDays: PropTypes.object,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  userId: PropTypes.number
};
