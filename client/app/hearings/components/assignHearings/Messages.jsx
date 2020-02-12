import React from 'react';

import COPY from '../../../../COPY';
import StatusMessage from '../../../components/StatusMessage';

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
