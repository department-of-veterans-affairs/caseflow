import React from 'react';

import Alert from 'app/components/Alert';
import { SUBSTITUTE_APPELLANT_SCHEDULE_HEARING_TASK_TEXT } from 'app/../COPY';

export const ScheduleHearingTaskAlert = (props) => (
  <Alert
    type="info"
    message={SUBSTITUTE_APPELLANT_SCHEDULE_HEARING_TASK_TEXT}
    {...props}
  />
);
