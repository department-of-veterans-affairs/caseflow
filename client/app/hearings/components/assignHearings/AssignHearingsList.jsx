import React from 'react';
import PropTypes from 'prop-types';

import { TimeSlotCard } from './TimeSlotCard';

export const AssignHearingsList = ({
  hearings,
  hearingDay,
  regionalOffice,
}) => {
  return hearings.map((hearing) => (
    <TimeSlotCard
      key={hearing.appealExternalId}
      hearing={hearing}
      hearingDay={hearingDay}
      regionalOffice={regionalOffice}
    />
  ));
};

AssignHearingsList.propTypes = {
  appeal: PropTypes.object,
  hearingDay: PropTypes.object,
  regionalOffice: PropTypes.string,
};
