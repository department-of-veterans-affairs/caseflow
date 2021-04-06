import React from 'react';

import { amaAppeal, powerOfAttorney } from '../../../../test/data/appeals';

import { LEGACY_APPEAL_TYPES } from '../../../queue/constants';
import { TimeSlotCard } from './TimeSlotCard';

export default {
  title: 'Hearings/Components/Schedule Hearing/TimeSlotCard',
  component: TimeSlotCard,
  argTypes: {
    appeal: { table: { disable: true } },
  }
};

const Template = (args) => {
  return (
    <TimeSlotCard
      {...args}
    />
  );
};

export const Basic = Template.bind({});
Basic.args = {
};
Basic.argTypes = {
  issueCount: { control: { type: 'number' } },
  caseType: { control: { type: 'select', options: ['Original', LEGACY_APPEAL_TYPES.CAVC_REMAND] } },
  docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
  veteranDateOfDeath: { control: { type: 'date' } }
};
