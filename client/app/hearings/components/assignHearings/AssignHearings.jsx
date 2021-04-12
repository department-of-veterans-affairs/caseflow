import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { NoUpcomingHearingDayMessage } from './Messages';
import AssignHearingsTabs from './AssignHearingsTabs';
import { HearingDaysNav } from './HearingDaysNav';

export const AssignHearings = ({
  upcomingHearingDays, selectedHearingDay, selectedRegionalOffice, onSelectedHearingDayChange
}) => {

  if (_.isEmpty(upcomingHearingDays)) {
    return <NoUpcomingHearingDayMessage />;
  }

  return (
    <React.Fragment>
      <HearingDaysNav
        upcomingHearingDays={upcomingHearingDays}
        selectedHearingDay={selectedHearingDay}
        onSelectedHearingDayChange={onSelectedHearingDayChange} />
      <AssignHearingsTabs
        selectedRegionalOffice={selectedRegionalOffice}
        selectedHearingDay={selectedHearingDay}
        room={selectedHearingDay?.room}
      />
    </React.Fragment>
  );
};

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
