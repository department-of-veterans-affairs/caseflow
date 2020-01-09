import React from 'react';
import StatusMessage from '../../../components/StatusMessage';
import COPY from '../../../../COPY.json';

export const NoUpcomingHearingDayMessage = () => (
  <div>
    <StatusMessage
      title={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_HEADER}
      type="alert"
      messageText={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_MESSAGE}
      wrapInAppSegment={false}
    />
  </div>
);
