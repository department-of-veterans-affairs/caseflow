import React from 'react';

import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import { roTimezones } from '../../utils';

import { TimeSlot } from './TimeSlot';

export default {
  title: 'Hearings/Components/Schedule Hearing/TimeSlot',
  component: TimeSlot,
  argTypes: {
    hearings: { table: { disable: true } },
    setTime: { table: { disable: true } },
  }
};

const Template = (args) => {
  return (
    <TimeSlot
      {...args}
      fetchScheduledHearings={() => false}
      hearings={[
        {
          hearingTime: args.hearingTime,
          docketName: args?.docketName,
          issueCount: args?.issueCount,
          poaName: args?.poaName
        }
      ]}
    />
  );
};

export const Basic = Template.bind({});
Basic.args = { hearingTime: HEARING_TIME_OPTIONS[0].value, roTimezone: roTimezones()[1] };
Basic.argTypes = {
  hearingTime: {
    control: {
      type: 'select',
      options: HEARING_TIME_OPTIONS.map((opt) => opt.value),
    },
  },
  roTimezone: { control: { type: 'select', options: roTimezones() } },
  docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
  issueCount: { control: { type: 'number' } },
  poaName: { control: { type: 'select', options: ['', 'American Legion'] } },
};
