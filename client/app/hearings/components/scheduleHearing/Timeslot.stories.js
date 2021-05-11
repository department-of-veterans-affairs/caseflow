import React from 'react';

import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import { roTimezones } from '../../utils';

import { TimeSlot } from './TimeSlot';

export default {
  title: 'Hearings/Components/Schedule Hearing/TimeSlot',
  component: TimeSlot,
  argTypes: {
    scheduledHearingsList: { table: { disable: true } },
    update: { table: { disable: true } },
    fetchScheduledHearings: { table: { disable: true } },
    onChange: { action: 'onChange' },
    hearingTime: {
      control: {
        type: 'select',
        options: HEARING_TIME_OPTIONS.map((opt) => opt.value),
      },
    },
    roTimezone: { control: { type: 'select', options: roTimezones() } },
    docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
    issueCount: { control: { type: 'number' } },
    poaName: { control: { type: 'select', options: ['', 'American Legion'] } }
  }
};

const Template = (args) => {
  return (
    <TimeSlot
      {...args}
      fetchScheduledHearings={() => false}
      scheduledHearingsList={[
        {
          externalId: 1,
          hearingTime: '08:45',
          docketName: 'legacy',
          issueCount: 2,
          poaName: 'American Legion'
        },
        {
          externalId: 2,
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
Basic.args = { hearingTime: HEARING_TIME_OPTIONS[0].value, ro: 'RO44', roTimezone: 'America/Los_Angeles' };
export const Denver = Template.bind({});
Denver.args = { hearingTime: HEARING_TIME_OPTIONS[0].value, ro: 'RO39', roTimezone: 'America/Denver' };
