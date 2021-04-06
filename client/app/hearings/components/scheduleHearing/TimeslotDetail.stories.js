import React from 'react';

import { TimeSlotDetail } from './TimeSlotDetail';
import { LEGACY_APPEAL_TYPES } from '../../../queue/constants';

export default {
  title: 'Hearings/Components/Schedule Hearing/TimeSlot Detail',
  component: TimeSlotDetail,
  argTypes: {
    docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
    issueCount: { control: { type: 'number' } },
    poaName: { control: { type: 'select', options: ['', 'American Legion'] } },
  }
};

const Template = (args) => {
  return <TimeSlotDetail {...args} />;
};

export const Basic = Template.bind({});
Basic.args = {
  label: 'Something',
  showDetails: true,
  issueCount: 1,
  poaName: 'American Legion',
  docketName: 'legacy',
  docketNumber: 1,
};

Basic.argTypes = {
  issueCount: { control: { type: 'number' } },
  caseType: { control: { type: 'select', options: ['Original', LEGACY_APPEAL_TYPES.CAVC_REMAND] } },
  docketName: { control: { type: 'select', options: ['', 'legacy', 'hearings'] } },
};
