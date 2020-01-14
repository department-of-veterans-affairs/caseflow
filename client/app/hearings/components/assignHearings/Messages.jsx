import { css } from 'glamor';
import React from 'react';

import COPY from '../../../../COPY.json';
import StatusMessage from '../../../components/StatusMessage';

export const NoUpcomingHearingDayMessage = () => (
  <div {...css({ marginTop: 50 })}>
    <StatusMessage
      title={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_HEADER}
      type="alert"
      messageText={COPY.ASSIGN_HEARINGS_TABS_NO_HEARING_DAY_MESSAGE}
      wrapInAppSegment={false}
    />
  </div>
);

export const NoVeteransToAssign = () => (
  <div>
    <StatusMessage
      title= {COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_HEADER}
      type="alert"
      messageText={COPY.ASSIGN_HEARINGS_TABS_VETERANS_NOT_ASSIGNED_MESSAGE}
      wrapInAppSegment={false}
    />
  </div>
);
