import React from 'react';

import { TimeSlotButton } from './TimeSlotButton';
import HEARING_TIME_OPTIONS from '../../../../constants/HEARING_TIME_OPTIONS';
import { roTimezones } from '../../utils';

export default {
  title: 'Hearings/Components/Schedule Hearing/TimeSlot Button',
  component: TimeSlotButton,
  argTypes: {
    onClick: { table: { disable: true } },
    docketName: {
      control: { type: 'select', options: ['', 'legacy', 'hearings'] },
    },
    issueCount: { control: { type: 'number' } },
    poaName: {
      control: {
        type: 'select',
        options: ['', 'American Legion', 'Some Super Long POA name that should be truncated'],
      },
    },
  },
};

const Template = (args) => {
  return <TimeSlotButton {...args} />;
};

export const Basic = Template.bind({});
Basic.args = {
  hearingTime: HEARING_TIME_OPTIONS[0].value,
  roTimezone: roTimezones()[0],
  selected: false,
};
Basic.argTypes = {
  hearingTime: {
    control: {
      type: 'select',
      options: HEARING_TIME_OPTIONS.map((opt) => opt.value),
    },
  },
  roTimezone: { control: { type: 'select', options: roTimezones() } },
};

export const Selected = Template.bind({});
Selected.args = {
  hearingTime: HEARING_TIME_OPTIONS[0].value,
  roTimezone: roTimezones()[0],
  selected: true,
};
Selected.argTypes = {
  hearingTime: {
    control: {
      type: 'select',
      options: HEARING_TIME_OPTIONS.map((opt) => opt.value),
    },
  },
  roTimezone: { control: { type: 'select', options: roTimezones() } },
};

export const FullSlot = Template.bind({});
FullSlot.args = {
  hearingTime: HEARING_TIME_OPTIONS[0].value,
  roTimezone: roTimezones()[0],
  selected: false,
  issueCount: 1,
  poaName: 'American Legion',
  docketName: 'legacy',
  docketNumber: 1,
  full: true
};
FullSlot.argTypes = {
  hearingTime: {
    control: {
      type: 'select',
      options: HEARING_TIME_OPTIONS.map((opt) => opt.value),
    },
  },
  roTimezone: { control: { type: 'select', options: roTimezones() } },
};
