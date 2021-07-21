import React from 'react';
import { css } from 'glamor';
import Alert from 'app/components/Alert';
import { SUBSTITUTE_APPELLANT_SCHEDULE_HEARING_TASK_TEXT } from 'app/../COPY';

const textStyling = css({
  fontSize: '1.7rem',
  lineHeight: '1',
});

const alert = <div {...textStyling}>{SUBSTITUTE_APPELLANT_SCHEDULE_HEARING_TASK_TEXT}</div>;

export const ScheduleHearingTaskAlert = (props) => (
  <Alert
    type="info"
    message={alert}
    {...props}
  />
);
